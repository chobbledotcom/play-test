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

    SEED_SECONDS = 15
    ATTEMPTS = 5

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
    end

    sig { void }
    def call
      ATTEMPTS.times do
        push_snapshot
        return if replica_seeded?

        sleep 2
      end

      message = "No Litestream snapshot appeared in #{replica_bucket}"
      raise "#{message} for #{replica_path}"
    end

    private

    sig { void }
    def push_snapshot
      runner.call(["bundle", "exec", "litestream", "replicate",
        "-config", config_path.to_s,
        "-exec", "sleep #{SEED_SECONDS}"])
    end

    sig { returns(T::Boolean) }
    def replica_seeded?
      command = ["bundle", "exec", "litestream", "snapshots",
        "-config", config_path.to_s, db_path.to_s]
      stdout, _success = runner.call(command)
      stdout.include?(replica_path)
    end

    sig { returns(String) }
    def config_path
      @config_path ||= begin
        file = Tempfile.new("magic-container-litestream")
        file.write(config_yaml)
        file.flush
        file.path
      end
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
      stdout, _stderr, status = Open3.capture3(*args)
      unless status.success?
        raise "Litestream command failed: #{args.join(" ")}"
      end

      [stdout, true]
    end

    sig { returns(String) }
    def replica_bucket = s3.bucket

    attr_reader :db_path
    attr_reader :replica_path
    attr_reader :s3
    attr_reader :runner
  end
end
