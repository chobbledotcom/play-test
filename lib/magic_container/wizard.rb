# typed: strict
# frozen_string_literal: true

require "active_storage/service/s3_service"
require "open3"
require "securerandom"
require "tmpdir"

module MagicContainer
  # Interactive wizard that turns a backup archive into a deployed Bunny
  # Magic Container. The container has no console access, so everything is
  # prepared up front: Active Storage files are uploaded to S3, the
  # databases are seeded into the Litestream replica the container restores
  # from on first boot, and the app is created with a full environment.
  # Every step persists enough state in the answers store that a failed
  # attempt can be retried without repeating completed work.
  class Wizard
    extend T::Sig

    CONTAINER_PORT = T.let(3000, Integer)
    # First deploys pull the whole image before the endpoint answers, which
    # regularly outlasts 30 seconds on a shared runtime.
    ENDPOINT_POLLS = T.let(60, Integer)
    POLL_SECONDS = T.let(5, Integer)

    sig do
      params(
        prompts: Prompts,
        store: AnswersStore
      ).void
    end
    def initialize(prompts: Prompts.new, store: AnswersStore.new)
      @prompts = prompts
      @store = store
      @bunny_access_key = T.let(nil, T.nilable(String))
    end

    sig { void }
    def call
      prompts.banner(t("banners.main"))
      answers = answers_to_use
      return unless confirm_plan(answers)

      # Saved only once the plan is confirmed: abandoning a run before this
      # point must not overwrite the retry state an earlier attempt left.
      store.save(answers)
      execute(answers)
    end

    private

    sig { returns(Answers) }
    def answers_to_use
      previous = store.load
      if previous && prompts.confirm(t("questions.confirm_reuse", path: store.path))
        validate_archive(previous.archive_path)
        prompts.note(t("notes.loaded_answers", path: store.path))
        return previous.with(
          rails_master_key: replenished_master_key(previous.rails_master_key)
        )
      end

      client = BunnyClient.new(access_key: bunny_access_key)
      Answers.new(
        access_key: bunny_access_key,
        app_name: prompts.ask(t("questions.app_name"), default: "play-test"),
        archive_path: ask_archive,
        **collect_deployment(client),
        **collect_storage,
        **collect_optional
      )
    end

    sig { params(client: BunnyClient).returns(T::Hash[Symbol, T.untyped]) }
    def collect_deployment(client)
      {
        region: ask_region(client),
        registry_id: ask_registry(client),
        image_ref: image_ref,
        image_tag: prompts.ask(t("questions.image_tag"), default: "latest"),
        runtime_type: ask_runtime_type,
        volume: prompts.confirm(t("questions.attach_volume")),
        volume_size_gb: ask_volume_size
      }
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def collect_storage
      {
        storage_s3: ask_s3_details(t("questions.storage_banner")),
        litestream_s3: ask_s3_details(t("questions.litestream_banner"))
      }
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def collect_optional
      {
        display_app_name: prompts.ask(
          t("questions.display_app_name"), default: "Play-Test"
        ),
        base_url: prompts.ask(t("questions.base_url"), default: ""),
        rails_master_key: ask_rails_master_key,
        sentry_dsn: prompts.ask(t("questions.sentry_dsn"), default: ""),
        secret_key_base: SecureRandom.hex(64)
      }
    end

    # Rails hex-unpacks RAILS_MASTER_KEY into a 16-byte AES-128 key for
    # credentials, so anything but 32 hex characters makes the container
    # crash-loop at boot ("key must be 16 bytes").
    sig { returns(String) }
    def ask_rails_master_key
      loop do
        key = prompts.secret(t("questions.master_key"), required: false)
        return key if master_key_valid?(key)

        prompts.note(t("notes.master_key_invalid"))
      end
    end

    # A store saved by an older wizard may hold a key the validation above
    # would never have accepted; re-ask rather than redeploy the bad value.
    sig { params(stored: String).returns(String) }
    def replenished_master_key(stored)
      return stored if master_key_valid?(stored)

      prompts.note(t("notes.master_key_replenishing"))
      ask_rails_master_key
    end

    sig { params(key: String).returns(T::Boolean) }
    def master_key_valid?(key)
      key.empty? || key.match?(/\A[0-9a-f]{32}\z/i)
    end

    sig { returns(String) }
    def bunny_access_key
      return @bunny_access_key if @bunny_access_key

      from_env = ENV["BUNNY_ACCESS_KEY"].to_s
      key = if from_env.empty?
        prompts.secret(t("questions.bunny_access_key"), required: true)
      elsif prompts.confirm(t("questions.bunny_key_from_env"))
        from_env
      else
        prompts.secret(t("questions.bunny_access_key"), required: true)
      end
      @bunny_access_key = key
    end

    sig { returns(Pathname) }
    def ask_archive
      latest = latest_archive&.to_s || ""
      answer = prompts.ask(t("questions.archive_path"), default: latest)
      path = Pathname.new(File.expand_path(answer))
      validate_archive(path)
      path
    end

    sig { params(path: Pathname).void }
    def validate_archive(path)
      raise t("errors.archive_not_found", path: path) unless path.file?
    end

    sig { returns(T.nilable(Pathname)) }
    def latest_archive
      dir = Rails.root.join("storage/backups")
      dir.glob("backup-*.tar.gz").max
    end

    sig { params(client: BunnyClient).returns(String) }
    def ask_region(client)
      optimal = client.optimal_region
      return optimal if prompts.confirm(t("questions.optimal_region", region: optimal))

      regions = client.regions.filter { it["hasCapacity"] }
      choices = regions.map do |region|
        name = region.fetch("name")
        ["#{name} (#{region.fetch("id")})", region.fetch("id")]
      end
      prompts.select(t("questions.region"), choices)
    end

    sig { params(client: BunnyClient).returns(String) }
    def ask_registry(client)
      choices = client.registries.map do |registry|
        name = registry.fetch("displayName")
        label = "#{name} (#{registry.fetch("hostName")})"
        [label, registry.fetch("id").to_s]
      end
      prompts.select(t("questions.registry"), choices)
    end

    sig { returns(String) }
    def image_ref
      prompts.ask(t("questions.image"), default: "chobble/play-test")
    end

    sig { returns(String) }
    def ask_runtime_type
      choices = [
        [t("questions.runtime_shared"), "shared"],
        [t("questions.runtime_reserved"), "reserved"]
      ]
      prompts.select(t("questions.runtime_type"), choices)
    end

    sig { returns(Integer) }
    def ask_volume_size
      loop do
        answer = prompts.ask(t("questions.volume_size"), default: "5")
        size = Integer(answer, exception: false)
        return size if size&.positive?

        prompts.note(t("notes.volume_size_invalid"))
      end
    end

    sig { params(label: String).returns(S3Details) }
    def ask_s3_details(label)
      prompts.banner(label)
      endpoint = prompts.ask(t("questions.s3_endpoint"))
      bucket = prompts.ask(t("questions.s3_bucket"))
      region = prompts.ask(t("questions.s3_region"), default: "us-east-1")
      access_key_id = prompts.ask(t("questions.s3_access_key_id"))
      secret = prompts.secret(t("questions.s3_secret_key"), required: true)
      S3Details.new(
        access_key_id: access_key_id,
        bucket: bucket,
        endpoint: endpoint,
        region: region,
        secret_access_key: secret
      )
    end

    sig { params(answers: Answers).returns(T::Boolean) }
    def confirm_plan(answers)
      prompts.banner(t("banners.plan"))
      summary_lines(answers).each { prompts.note(it) }
      prompts.confirm(t("questions.confirm_plan"))
    end

    sig { params(answers: Answers).returns(T::Array[String]) }
    def summary_lines(answers)
      storage = answers.storage_s3
      litestream = answers.litestream_s3
      image = "#{answers.image_ref}:#{answers.image_tag}"
      [
        t("plan.archive", archive: answers.archive_path.basename),
        t("plan.app", app: answers.app_name, region: answers.region,
          runtime: answers.runtime_type),
        t("plan.image", image: image),
        volume_summary(answers),
        t("plan.storage", bucket: storage.bucket, endpoint: storage.endpoint),
        t("plan.litestream", bucket: litestream.bucket, endpoint: litestream.endpoint),
        t("plan.db_restore"),
        t("plan.storage_upload"),
        t("plan.secret_generated")
      ]
    end

    sig { params(answers: Answers).returns(String) }
    def volume_summary(answers)
      return t("plan.volume_with", size: answers.volume_size_gb) if answers.volume

      t("plan.volume_without")
    end

    sig { params(answers: Answers).void }
    def execute(answers)
      client = BunnyClient.new(access_key: answers.access_key)
      workdir = Pathname.new(
        Dir.mktmpdir("magic-container-", Rails.root.join("tmp"))
      )
      storage_service = build_storage_service(answers.storage_s3)

      restore_backup(answers, workdir, storage_service)
      answers = seed_database_replicas(answers, workdir)
      answers = find_or_create_app(client, answers)
      app_id = T.must(answers.app_id)
      client.deploy(app_id)
      url = container_url(client, app_id, answers)
      if answers.base_url.empty?
        # Persisted so a retry reuses the resolved url instead of treating
        # the resolved deployment as still unresolved.
        answers = answers.with(base_url: url)
        store.save(answers)
      end
      report(answers, app_id, url, workdir)
    end

    sig { params(s3: S3Details).returns(ActiveStorage::Service::S3Service) }
    def build_storage_service(s3)
      ActiveStorage::Service::S3Service.new(
        access_key_id: s3.access_key_id,
        bucket: s3.bucket,
        endpoint: s3.endpoint,
        region: s3.region,
        secret_access_key: s3.secret_access_key
      )
    end

    sig do
      params(
        answers: Answers,
        workdir: Pathname,
        storage_service: ActiveStorage::Service::S3Service
      ).void
    end
    def restore_backup(answers, workdir, storage_service)
      prompts.note(t("notes.restoring"))
      result = RestoreService.new.perform(
        archive_dir: answers.archive_path.dirname,
        date: backup_date(answers.archive_path),
        db_paths: archive_database_paths(answers.archive_path, workdir),
        service_name: "s3_host",
        skip_existing_uploads: true,
        storage_service: storage_service,
        storage_target: :s3
      )
      names = result[:restored_databases].join(", ")
      prompts.note(t("notes.restored_databases", names: names))
      existing = result.fetch(:storage_files_skipped)
      if existing.positive?
        prompts.note(t("notes.files_skipped", count: existing))
      end
    end

    sig { params(archive_path: Pathname).returns(String) }
    def backup_date(archive_path)
      pattern = /backup-(\d{4}-\d{2}-\d{2})\.tar\.gz\z/
      match = archive_path.basename.to_s.match(pattern)
      if match.nil?
        raise t("errors.backup_date_missing", name: archive_path.basename)
      end

      T.must(match[1])
    end

    sig do
      params(
        archive_path: Pathname,
        workdir: Pathname
      ).returns(T::Array[Pathname])
    end
    def archive_database_paths(archive_path, workdir)
      stdout, status = Open3.capture2("tar", "-tzf", archive_path.to_s)
      raise t("errors.archive_listing_failed", archive: archive_path) unless status.success?

      names = stdout.lines.map(&:chomp)
        .select { it.start_with?("db/") && it.end_with?(".sqlite3") }
        .map { it.delete_prefix("db/") }
      raise t("errors.no_databases", archive: archive_path) if names.empty?

      names.map { workdir.join(it) }
    end

    # Returns the answers so the execution flow keeps whatever seeding
    # progress was persisted along the way.
    sig { params(answers: Answers, workdir: Pathname).returns(Answers) }
    def seed_database_replicas(answers, workdir)
      prompts.note(t("notes.seeding"))
      litestream_entries.each do |name, replica_path|
        db_path = workdir.join(name)
        next unless db_path.exist?
        if answers.seeded_replica_paths.include?(replica_path)
          prompts.note(t("notes.seeded_skip", name: name))
          next
        end

        seeder = LitestreamSeeder.new(
          db_path: db_path,
          replica_path: replica_path,
          s3: answers.litestream_s3
        )
        seeder.call
        prompts.note(t("notes.seeded", name: name, replica_path: replica_path))
        answers = record_seeded(answers, replica_path)
      end
      answers
    end

    # Persisted the moment the seed lands, so the skip above only ever
    # trusts work this answers lineage performed - data some other
    # deployment left in the bucket is always re-seeded, never mistaken
    # for this backup's seed.
    sig { params(answers: Answers, replica_path: String).returns(Answers) }
    def record_seeded(answers, replica_path)
      updated = answers.with(
        seeded_replica_paths: answers.seeded_replica_paths + [replica_path]
      )
      store.save(updated)
      updated
    end

    # Which databases the container restores, mirroring config/litestream.yml
    # so the seeded replicas land exactly where the entrypoint looks.
    sig { returns(T::Array[[String, String]]) }
    def litestream_entries
      config = YAML.load_file(Rails.root.join("config/litestream.yml"))
      Array(config.fetch("dbs")).map do |db|
        source = Pathname.new(db.fetch("path")).basename.to_s
        replicas = Array(db.fetch("replicas"))
        replica_path = T.cast(replicas.first, T::Hash[String, T.untyped])
          .fetch("path", source)
        [source, replica_path]
      end
    end

    # Returns the answers with the app id set, so the execution flow keeps
    # whatever the attempt went as far as persisting.
    sig { params(client: BunnyClient, answers: Answers).returns(Answers) }
    def find_or_create_app(client, answers)
      existing_id = answers.app_id
      if existing_id
        prompts.note(t("notes.app_reused", id: existing_id))
        return answers
      end

      app_id = orphaned_app_id(client, answers)
      if app_id
        prompts.note(t("notes.orphan_reused", id: app_id))
      else
        prompts.note(t("notes.creating_app"))
        app_id = client.create_application(
          container: container_for(answers),
          name: answers.app_name,
          region: answers.region,
          runtime_type: answers.runtime_type,
          volume: answers.volume ? answers.volume_size_gb : nil
        )
      end
      # Persisted at once so a failure after creating - or recovering - an
      # app retries against the same id instead of duplicating it.
      answers = answers.with(app_id: app_id)
      store.save(answers)
      answers
    end

    # Bunny only reveals an application's id in the create response; a
    # create whose response never came back (network failure after Bunny
    # built the app) leaves an orphan no retry can know by id. Name matches
    # are verified against the confirmed plan and offered for reuse before
    # another create can duplicate them.
    sig { params(client: BunnyClient, answers: Answers).returns(T.nilable(String)) }
    def orphaned_app_id(client, answers)
      matches = matching_apps(client, answers)
      return if matches.empty?

      if matches.one?
        app_id = T.must(matches.first).fetch("id").to_s
        return app_id if prompts.confirm(
          t("questions.reuse_orphan", id: app_id, name: answers.app_name),
          default: false
        )

        return nil
      end

      choices = matches.map do |app|
        label = t("questions.orphan_choice", id: app.fetch("id"), name: app.fetch("name"))
        [label, app.fetch("id").to_s]
      end
      choices.push([t("questions.orphan_create"), ""])
      prompts.select(t("questions.orphan_select", name: answers.app_name), choices)
        .presence
    end

    # Same-named apps are reconciled by fetching each candidate's full
    # application, because a reused app keeps its deployed image, registry,
    # runtime, region, volume and endpoints - only the environment is
    # replaced. The listing carries no template detail to verify, and an
    # app not configured exactly as the confirmed plan asks is never
    # offered; a fresh one is created instead.
    sig do
      params(
        client: BunnyClient,
        answers: Answers
      ).returns(T::Array[T::Hash[String, T.untyped]])
    end
    def matching_apps(client, answers)
      client.applications
        .select { it["name"] == answers.app_name }
        .filter_map { |listed| client.application(listed.fetch("id").to_s) }
        .select { |app| orphan_matches_plan?(app, answers) }
    end

    sig do
      params(
        app: T::Hash[String, T.untyped],
        answers: Answers
      ).returns(T::Boolean)
    end
    def orphan_matches_plan?(app, answers)
      template = app.fetch("containerTemplates").first
      endpoints = Array(template.fetch("endpoints"))
      template.fetch("imageName") == image_name(answers.image_ref) &&
        template.fetch("imageNamespace") == image_namespace(answers.image_ref) &&
        template.fetch("imageTag") == answers.image_tag &&
        template.fetch("imageRegistryId").to_s == answers.registry_id &&
        Array(template.fetch("volumeMounts")).any? == answers.volume &&
        app.fetch("runtimeType") == answers.runtime_type &&
        app.fetch("regionSettings").fetch("requiredRegionIds")
          .include?(answers.region) &&
        endpoints.any? { it.fetch("publicHost", "").end_with?(".bunny.run") }
    end

    sig do
      params(answers: Answers).returns(T::Hash[String, T.untyped])
    end
    def container_for(answers)
      container = {
        endpoints: container_endpoints,
        environmentVariables: EnvBuilder.build(answers)
          .map { |name, value| {name: name, value: value} },
        imageName: image_name(answers.image_ref),
        imageNamespace: image_namespace(answers.image_ref),
        # The wizard deploys a mutable tag (latest), so every deploy must
        # pull fresh rather than reuse whatever the node already cached.
        imagePullPolicy: "always",
        imageRegistryId: answers.registry_id,
        imageTag: answers.image_tag,
        name: "app"
      }
      if answers.volume
        container[:volumeMounts] = [
          {mountPath: "/rails/storage", name: "storage"}
        ]
      end
      container
    end

    sig { returns(T::Array[T::Hash[String, T.untyped]]) }
    def container_endpoints
      [{
        cdn: {
          isSslEnabled: false,
          portMappings: [{containerPort: CONTAINER_PORT}]
        },
        displayName: "web"
      }]
    end

    sig { params(image_ref: String).returns(String) }
    def image_namespace(image_ref)
      image_ref.include?("/") ? image_ref.split("/").first : "library"
    end

    sig { params(image_ref: String).returns(String) }
    def image_name(image_ref)
      image_ref.include?("/") ? image_ref.split("/", 2).last : image_ref
    end

    # Returns the final public URL. The container's environment is always
    # replaced from the final answers before a restart: a reused app still
    # runs whatever the failed attempt left behind, which can be a
    # malformed RAILS_MASTER_KEY or a stale env from before the answers
    # were corrected, and the running pod only picks a replaced
    # environment up on restart.
    sig do
      params(
        client: BunnyClient,
        app_id: String,
        answers: Answers
      ).returns(String)
    end
    def container_url(client, app_id, answers)
      prompts.note(t("notes.waiting_endpoint"))
      endpoint = await_endpoint(client, app_id)
      host = endpoint.fetch("publicHost")
      url = answers.base_url.presence || "https://#{host}"
      env = EnvBuilder.build(answers.with(base_url: url)).to_h
      client.replace_env(app_id, endpoint.fetch("containerId"), env)
      client.restart(app_id)
      prompts.note(t("notes.base_url_set", url: url))
      url
    end

    sig do
      params(
        client: BunnyClient,
        app_id: String
      ).returns(T::Hash[String, T.untyped])
    end
    def await_endpoint(client, app_id)
      ENDPOINT_POLLS.times do
        candidates = client.endpoints(app_id)
        endpoint = candidates.find do |candidate|
          candidate["publicHost"].to_s.include?(".bunny.run")
        end
        return T.cast(endpoint, T::Hash[String, T.untyped]) if endpoint

        sleep POLL_SECONDS
      end
      raise t("errors.endpoint_missing", id: app_id)
    end

    sig do
      params(
        answers: Answers,
        app_id: String,
        url: String,
        workdir: Pathname
      ).void
    end
    def report(answers, app_id, url, workdir)
      prompts.banner(t("banners.deployed"))
      prompts.note(t("notes.report_app", app: answers.app_name, id: app_id))
      prompts.note(t("notes.report_url", url: url))
      prompts.note(t("notes.report_workdir", path: workdir))
      prompts.note(t("notes.report_first_boot"))
      backup = answers.base_url.presence || url
      prompts.note(t("notes.report_base_url", url: backup))

      env_path = save_env_file(answers, app_id)
      prompts.note(t("notes.env_saved", path: env_path))
    end

    sig { params(answers: Answers, app_id: String).returns(Pathname) }
    def save_env_file(answers, app_id)
      dir = Rails.root.join("tmp/magic-container")
      FileUtils.mkdir_p(dir)
      path = dir.join("#{app_id}.env")
      lines = EnvBuilder.build(answers).map { |name, value| "#{name}=#{value}" }
      # The file holds every secret, so it must never exist with wider
      # permissions than the creation mode.
      File.open(path, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
        file.write(lines.join("\n") + "\n")
      end
      FileUtils.chmod(0o600, path)
      path
    end

    sig do
      params(key: String, values: T::Hash[Symbol, T.untyped]).returns(String)
    end
    def t(key, values = {})
      I18n.t("magic_container.wizard.#{key}", **values)
    end

    sig { returns(Prompts) }
    attr_reader :prompts

    sig { returns(AnswersStore) }
    attr_reader :store
  end
end
