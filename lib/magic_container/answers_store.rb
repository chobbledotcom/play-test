# typed: strict
# frozen_string_literal: true

module MagicContainer
  # Persists the wizard's answers in a dotenv-style file so a failed attempt
  # can be retried without re-entering every answer. The file holds every
  # secret, so it lives git-ignored (/.env* in .gitignore) with owner-only
  # permissions, and records the created app id and seeded replica paths for
  # idempotent retries. Values are written raw to end of line - no quoting or
  # substitution - and read back the same way, so secrets survive the round
  # trip untouched. Saves are atomic: the dump lands in a sibling temporary
  # file that is renamed over the store, so an interrupted save never
  # destroys the previous complete state.
  class AnswersStore
    extend T::Sig

    BUNNY_KEY = "MAGIC_BUNNY_ACCESS_KEY"
    STORAGE_PREFIX = "MAGIC_STORAGE_S3"
    LITESTREAM_PREFIX = "MAGIC_LITESTREAM_S3"

    sig { params(path: T.nilable(Pathname)).void }
    def initialize(path: nil)
      @path = path || default_path
    end

    sig { returns(T.nilable(Answers)) }
    def load
      return unless path.file?

      env = parse(path.read)
      return if env.empty?

      answers_from(env)
    end

    sig { params(answers: Answers).void }
    def save(answers)
      # An interrupted save must not destroy the last complete state - the
      # dump lands in a git-ignored sibling (/.env* in .gitignore) and is
      # renamed over the store atomically. Both files hold every secret, so
      # both live with owner-only permissions.
      temp_path = Pathname.new("#{path}.tmp")
      File.open(temp_path, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
        file.write(dump(answers))
        file.flush
        file.fsync
      end
      File.rename(temp_path, path)
      FileUtils.chmod(0o600, path)
    end

    sig { returns(Pathname) }
    attr_reader :path

    private

    sig { returns(Pathname) }
    def default_path = Rails.root.join(".env.magic_container")

    sig { params(answers: Answers).returns(String) }
    def dump(answers)
      entries(answers).sort.map { |key, value| "#{key}=#{value}" }.join("\n") + "\n"
    end

    sig { params(answers: Answers).returns(T::Array[[String, String]]) }
    def entries(answers)
      s3_entries(STORAGE_PREFIX, answers.storage_s3) +
        s3_entries(LITESTREAM_PREFIX, answers.litestream_s3) + base_entries(answers)
    end

    sig { params(answers: Answers).returns(T::Array[[String, String]]) }
    def base_entries(answers)
      entries = [
        ["MAGIC_APP_NAME", answers.app_name],
        ["MAGIC_ARCHIVE_PATH", answers.archive_path.to_s],
        [BUNNY_KEY, answers.access_key],
        ["MAGIC_BASE_URL", answers.base_url],
        ["MAGIC_DISPLAY_APP_NAME", answers.display_app_name],
        ["MAGIC_IMAGE_REF", answers.image_ref],
        ["MAGIC_IMAGE_TAG", answers.image_tag],
        ["MAGIC_RAILS_MASTER_KEY", answers.rails_master_key],
        ["MAGIC_REGISTRY_ID", answers.registry_id],
        ["MAGIC_REGION", answers.region],
        ["MAGIC_RUNTIME_TYPE", answers.runtime_type],
        ["MAGIC_SECRET_KEY_BASE", answers.secret_key_base],
        ["MAGIC_SENTRY_DSN", answers.sentry_dsn],
        ["MAGIC_VOLUME", answers.volume.to_s],
        ["MAGIC_VOLUME_SIZE_GB", answers.volume_size_gb.to_s]
      ]
      app_id = answers.app_id
      entries.push(["MAGIC_APP_ID", app_id]) if app_id
      seeded = answers.seeded_replica_paths
      entries.push(["MAGIC_SEEDED_REPLICA_PATHS", seeded.join(",")]) if seeded.any?
      entries
    end

    sig do
      params(
        prefix: String,
        s3: S3Details
      ).returns(T::Array[[String, String]])
    end
    def s3_entries(prefix, s3)
      [
        ["#{prefix}_ACCESS_KEY_ID", s3.access_key_id],
        ["#{prefix}_BUCKET", s3.bucket],
        ["#{prefix}_ENDPOINT", s3.endpoint],
        ["#{prefix}_REGION", s3.region],
        ["#{prefix}_SECRET_ACCESS_KEY", s3.secret_access_key]
      ]
    end

    # One KEY=value per line, value running raw to end of line. Only the
    # line terminator is dropped, so leading and trailing whitespace in a
    # value survives the round trip - stripping the whole line would alter
    # secrets and archive paths the wizard promised to restore verbatim.
    sig { params(content: String).returns(T::Hash[String, String]) }
    def parse(content)
      content.each_line.filter_map do |line|
        trimmed = line.strip
        next if trimmed.empty? || trimmed.start_with?("#")

        key, value = line.chomp.split("=", 2)
        next if key.blank? || value.nil?

        [key, value]
      end.to_h
    end

    sig { params(env: T::Hash[String, String]).returns(Answers) }
    def answers_from(env)
      Answers.new(
        access_key: env.fetch(BUNNY_KEY),
        app_id: env["MAGIC_APP_ID"].presence,
        app_name: env.fetch("MAGIC_APP_NAME"),
        archive_path: Pathname.new(env.fetch("MAGIC_ARCHIVE_PATH")),
        base_url: env.fetch("MAGIC_BASE_URL"),
        display_app_name: env.fetch("MAGIC_DISPLAY_APP_NAME"),
        image_ref: env.fetch("MAGIC_IMAGE_REF"),
        image_tag: env.fetch("MAGIC_IMAGE_TAG"),
        rails_master_key: env.fetch("MAGIC_RAILS_MASTER_KEY"),
        registry_id: env.fetch("MAGIC_REGISTRY_ID"),
        region: env.fetch("MAGIC_REGION"),
        runtime_type: env.fetch("MAGIC_RUNTIME_TYPE"),
        secret_key_base: env.fetch("MAGIC_SECRET_KEY_BASE"),
        seeded_replica_paths: env["MAGIC_SEEDED_REPLICA_PATHS"].to_s.split(","),
        sentry_dsn: env.fetch("MAGIC_SENTRY_DSN"),
        storage_s3: s3_details(env, STORAGE_PREFIX),
        litestream_s3: s3_details(env, LITESTREAM_PREFIX),
        volume: env.fetch("MAGIC_VOLUME") == "true",
        volume_size_gb: Integer(env.fetch("MAGIC_VOLUME_SIZE_GB"))
      )
    end

    sig do
      params(
        env: T::Hash[String, String],
        prefix: String
      ).returns(S3Details)
    end
    def s3_details(env, prefix)
      S3Details.new(
        access_key_id: env.fetch("#{prefix}_ACCESS_KEY_ID"),
        bucket: env.fetch("#{prefix}_BUCKET"),
        endpoint: env.fetch("#{prefix}_ENDPOINT"),
        region: env.fetch("#{prefix}_REGION"),
        secret_access_key: env.fetch("#{prefix}_SECRET_ACCESS_KEY")
      )
    end
  end
end
