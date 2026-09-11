# typed: strict
# frozen_string_literal: true

require "open3"
require "securerandom"
require "tmpdir"

module MagicContainer
  # Interactive wizard that turns a backup archive into a deployed Bunny
  # Magic Container. The container has no console access, so everything is
  # prepared up front: Active Storage files are uploaded to S3, the
  # databases are seeded into the Litestream replica the container restores
  # from on first boot, and the app is created with a full environment.
  class Wizard
    extend T::Sig

    CONTAINER_PORT = T.let(3000, Integer)
    ENDPOINT_POLLS = T.let(10, Integer)

    sig { params(prompts: Prompts).void }
    def initialize(prompts: Prompts.new)
      @prompts = prompts
      @bunny_access_key = T.let(nil, T.nilable(String))
    end

    sig { void }
    def call
      prompts.banner("Bunny Magic Container from a backup")
      answers = collect
      return unless confirm_plan(answers)

      execute(answers)
    end

    private

    sig { returns(Answers) }
    def collect
      client = BunnyClient.new(access_key: bunny_access_key)
      Answers.new(
        access_key: bunny_access_key,
        app_name: prompts.ask("Bunny application name", default: "play-test"),
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
        image_tag: prompts.ask("Image tag", default: "latest"),
        runtime_type: ask_runtime_type,
        volume: prompts.confirm(
          "Attach a persistent volume for the databases?"
        ),
        volume_size_gb: ask_volume_size
      }
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def collect_storage
      {
        storage_s3: ask_s3_details("Active Storage S3 (uploaded files)"),
        litestream_s3: ask_s3_details("Litestream S3 (database replicas)")
      }
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def collect_optional
      {
        display_app_name: prompts.ask(
          "Display app name (APP_NAME)", default: "Play-Test"
        ),
        base_url: prompts.ask(
          "Public base URL (blank to use container URL)", default: ""
        ),
        rails_master_key: prompts.secret("RAILS_MASTER_KEY", required: false),
        sentry_dsn: prompts.ask("Sentry DSN", default: ""),
        secret_key_base: SecureRandom.hex(64)
      }
    end

    sig { returns(String) }
    def bunny_access_key
      return @bunny_access_key if @bunny_access_key

      from_env = ENV["BUNNY_ACCESS_KEY"].to_s
      key = if from_env.empty?
        prompts.secret("Bunny API access key", required: true)
      elsif prompts.confirm("Use the BUNNY_ACCESS_KEY from your environment?")
        from_env
      else
        prompts.secret("Bunny API access key", required: true)
      end
      @bunny_access_key = key
    end

    sig { returns(Pathname) }
    def ask_archive
      latest = latest_archive&.to_s || ""
      answer = prompts.ask("Backup archive path", default: latest)
      path = Pathname.new(File.expand_path(answer))
      raise "Archive not found: #{path}" unless path.file?

      path
    end

    sig { returns(T.nilable(Pathname)) }
    def latest_archive
      dir = Rails.root.join("storage/backups")
      dir.glob("backup-*.tar.gz").max
    end

    sig { params(client: BunnyClient).returns(String) }
    def ask_region(client)
      optimal = client.optimal_region
      return optimal if prompts.confirm("Use the optimal region (#{optimal})?")

      regions = client.regions.filter { it["hasCapacity"] }
      choices = regions.map do |region|
        name = region.fetch("name")
        ["#{name} (#{region.fetch("id")})", region.fetch("id")]
      end
      prompts.select("Region", choices)
    end

    sig { params(client: BunnyClient).returns(String) }
    def ask_registry(client)
      choices = client.registries.map do |registry|
        name = registry.fetch("displayName")
        label = "#{name} (#{registry.fetch("hostName")})"
        [label, registry.fetch("id").to_s]
      end
      prompts.select("Image registry", choices)
    end

    sig { returns(String) }
    def image_ref
      prompts.ask("Image (namespace/name)", default: "chobble/play-test")
    end

    sig { returns(String) }
    def ask_runtime_type
      choices = [
        ["Shared (cheaper, burstable resources)", "shared"],
        ["Reserved (dedicated resources)", "reserved"]
      ]
      prompts.select("Runtime type", choices)
    end

    sig { returns(Integer) }
    def ask_volume_size
      loop do
        answer = prompts.ask("Volume size (GB)", default: "5")
        size = Integer(answer, exception: false)
        return size if size&.positive?

        prompts.note("Enter a positive whole number of gigabytes")
      end
    end

    sig { params(label: String).returns(S3Details) }
    def ask_s3_details(label)
      prompts.banner(label)
      endpoint = prompts.ask("Endpoint (e.g. https://storage.bunnycdn.com)")
      bucket = prompts.ask("Bucket")
      region = prompts.ask("Region", default: "us-east-1")
      access_key_id = prompts.ask("Access key id")
      secret = prompts.secret("Secret access key", required: true)
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
      prompts.banner("Plan")
      summary_lines(answers).each { prompts.note(it) }
      prompts.confirm("Create the Magic Container with these settings?")
    end

    sig { params(answers: Answers).returns(T::Array[String]) }
    def summary_lines(answers)
      storage = answers.storage_s3
      litestream = answers.litestream_s3
      app_name = answers.app_name
      runtime = answers.runtime_type
      region = answers.region
      [
        "Archive: #{answers.archive_path.basename}",
        "App: #{app_name} (#{runtime}) in #{region}",
        "Image: #{answers.image_ref}:#{answers.image_tag}",
        "Volume: #{volume_summary(answers)}",
        "Active Storage S3: #{storage.bucket} at #{storage.endpoint}",
        "Litestream S3: #{litestream.bucket} at #{litestream.endpoint}",
        "Databases will be restored from the archive and seeded to Litestream",
        "Active Storage files will be uploaded to the S3 bucket",
        "A new SECRET_KEY_BASE was generated"
      ]
    end

    sig { params(answers: Answers).returns(String) }
    def volume_summary(answers)
      return "#{answers.volume_size_gb}GB persistent volume" if answers.volume

      "none, databases re-restore from Litestream on boot"
    end

    sig { params(answers: Answers).void }
    def execute(answers)
      client = BunnyClient.new(access_key: answers.access_key)
      workdir = Pathname.new(
        Dir.mktmpdir("magic-container-", Rails.root.join("tmp"))
      )
      storage_service = build_storage_service(answers.storage_s3)

      restore_backup(answers, workdir, storage_service)
      seed_database_replicas(answers, workdir)
      app_id = create_app(client, answers)
      client.deploy(app_id)
      url = container_url(client, app_id, answers)
      answers = answers.with(base_url: url) if answers.base_url.empty?
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
      prompts.note("Restoring backup and uploading Active Storage files...")
      result = RestoreService.new.perform(
        archive_dir: answers.archive_path.dirname,
        date: backup_date(answers.archive_path),
        db_paths: archive_database_paths(answers.archive_path, workdir),
        service_name: "s3_host",
        storage_service: storage_service,
        storage_target: :s3
      )
      names = result[:restored_databases].join(", ")
      prompts.note("Restored databases: #{names}")
    end

    sig { params(archive_path: Pathname).returns(String) }
    def backup_date(archive_path)
      pattern = /backup-(\d{4}-\d{2}-\d{2})\.tar\.gz\z/
      match = archive_path.basename.to_s.match(pattern)
      if match.nil?
        raise "Cannot read a backup date from #{archive_path.basename}"
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
      raise "Could not list #{archive_path}" unless status.success?

      names = stdout.lines.map(&:chomp)
        .select { it.start_with?("db/") && it.end_with?(".sqlite3") }
        .map { it.delete_prefix("db/") }
      raise "No databases found in #{archive_path}" if names.empty?

      names.map { workdir.join(it) }
    end

    sig { params(answers: Answers, workdir: Pathname).void }
    def seed_database_replicas(answers, workdir)
      prompts.note("Seeding Litestream replicas from the restored databases...")
      litestream_entries.each do |name, replica_path|
        db_path = workdir.join(name)
        next unless db_path.exist?

        seeder = LitestreamSeeder.new(
          db_path: db_path,
          replica_path: replica_path,
          s3: answers.litestream_s3
        )
        seeder.call
        prompts.note("Seeded #{name} to #{replica_path}")
      end
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

    sig { params(client: BunnyClient, answers: Answers).returns(String) }
    def create_app(client, answers)
      prompts.note("Creating the Magic Container app...")
      client.create_application(
        container: container_for(answers),
        name: answers.app_name,
        region: answers.region,
        runtime_type: answers.runtime_type,
        volume: answers.volume ? answers.volume_size_gb : nil
      )
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

    # Returns the final public URL. When no BASE_URL was given, the URL the
    # container answers on is pushed into the environment after deploy.
    sig do
      params(
        client: BunnyClient,
        app_id: String,
        answers: Answers
      ).returns(String)
    end
    def container_url(client, app_id, answers)
      prompts.note("Waiting for the container endpoint...")
      endpoint = await_endpoint(client, app_id)
      url = "https://#{endpoint.fetch("publicHost")}"
      return url if answers.base_url.present?

      container_id = endpoint.fetch("containerId")
      env = EnvBuilder.build(answers.with(base_url: url)).to_h
      client.replace_env(app_id, container_id, env)
      prompts.note("BASE_URL set to #{url}")
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

        sleep 3
      end
      raise "No container endpoint appeared for app #{app_id}"
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
      prompts.banner("Deployed")
      prompts.note("App: #{answers.app_name} (id #{app_id})")
      prompts.note("URL: #{url}")
      prompts.note("Working files kept in #{workdir}")
      prompts.note("First boot restores databases via Litestream")
      backup = answers.base_url.presence || url
      prompts.note("BASE_URL is set to #{backup}")

      env_path = save_env_file(answers, app_id)
      prompts.note("Environment record saved to #{env_path}")
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

    attr_reader :prompts
  end
end
