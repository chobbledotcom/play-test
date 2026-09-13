# typed: strict
# frozen_string_literal: true

require "open3"
require "tempfile"

module MagicContainer
  # Seeds a Litestream replica from a local database file so a Magic
  # Container (which has no console access) restores this database on its
  # first boot. Mirrors the replica layout config/litestream.yml defines,
  # which is what the container's entrypoint restores from.
  class LitestreamSeeder
    extend T::Sig

    Runner = T.type_alias do
      T.proc.params(args: T::Array[String]).returns([String, T::Boolean])
    end

    SEED_SECONDS = T.let(15, Integer)
    ATTEMPTS = T.let(5, Integer)

    sig do
      params(
        db_path: Pathname,
        replica_path: String,
        s3: S3Details,
        runner: T.nilable(Runner)
      ).void
    end
    def initialize(db_path:, replica_path:, s3:, runner: nil)
      @db_path = db_path
      @replica_path = replica_path
      @s3 = s3
      @runner = runner || lambda { |args| litestream_run(args) }
      # Held so the Tempfile is not garbage collected while the litestream
      # child process still reads its path.
      @config_file = T.let(nil, T.nilable(Tempfile))
    end

    sig { void }
    def call
      ATTEMPTS.times do
        push_snapshot
        return if replica_holds_snapshot?

        sleep 2
      end

      raise I18n.t("magic_container.litestream_seeder.errors.no_snapshot",
        bucket: replica_bucket, replica_path: replica_path, listing: listing)
    ensure
      close_config
    end

    # Any row beyond the header means the replica holds a snapshot. litestream
    # resumes the generation a re-push finds rather than adding a new
    # snapshot row, so growth cannot serve as the success signal - only
    # presence can. A failed litestream command raises on its own, and the
    # wizard only pushes where its persisted state says this archive has not
    # yet been seeded (state the archive digest invalidates when the backup
    # file is regenerated).
    sig { returns(T::Boolean) }
    def replica_holds_snapshot?
      listing.lines.count > 1
    end

    # The snapshot listing from litestream v0.3.13: a header row followed by
    # one row per snapshot. Rows carry the replica name ("s3"), generation,
    # index, size and creation time - never the replica path. The generated
    # config carries the S3 secret, so it never survives the listing.
    sig { returns(String) }
    def listing
      command = ["bundle", "exec", "litestream", "snapshots",
        "-config", config_path.to_s, db_path.to_s]
      stdout, _success = runner.call(command)
      stdout
    ensure
      close_config
    end

    private

    # The generated config carries the S3 secret, so it must not survive
    # whichever public method last needed it. close! unlinks the file, so
    # the reference is dropped too, letting a later command write a fresh
    # one.
    sig { void }
    def close_config
      file = @config_file
      @config_file = nil
      file&.close!
    end

    sig { void }
    def push_snapshot
      runner.call(["bundle", "exec", "litestream", "replicate",
        "-config", config_path.to_s,
        "-exec", "sleep #{SEED_SECONDS}"])
    end

    sig { returns(String) }
    def config_path
      file = @config_file
      return file.path if file

      file = Tempfile.new("magic-container-litestream")
      file.write(config_yaml)
      file.flush
      @config_file = file
      file.path
    end

    sig { returns(String) }
    def config_yaml
      config = {
        "dbs" => [{
          "path" => db_path.to_s,
          "replicas" => [{
            "access-key-id" => s3.access_key_id,
            "bucket" => s3.bucket,
            "endpoint" => s3.endpoint,
            "path" => replica_path,
            "region" => s3.region,
            "secret-access-key" => s3.secret_access_key,
            "sync-interval" => "10s",
            "type" => "s3"
          }]
        }]
      }
      YAML.dump(config)
    end

    sig { params(args: T::Array[String]).returns([String, T::Boolean]) }
    def litestream_run(args)
      stdout, stderr, status = Open3.capture3(*args)
      unless status.success?
        detail = stderr.empty? ? stdout : stderr
        raise I18n.t("magic_container.litestream_seeder.errors.command_failed",
          command: args.join(" "), detail: detail)
      end

      [stdout, true]
    end

    sig { returns(String) }
    def replica_bucket = s3.bucket

    sig { returns(Pathname) }
    attr_reader :db_path

    sig { returns(String) }
    attr_reader :replica_path

    sig { returns(S3Details) }
    attr_reader :s3

    sig { returns(Runner) }
    attr_reader :runner
  end
end
