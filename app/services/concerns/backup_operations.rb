# typed: strict
# frozen_string_literal: true

require "aws-sdk-s3"

# Shared operations for backing up and restoring the whole storage: every
# file-based SQLite database plus all Active Storage files. Archives are tar.gz
# files containing a db/ folder and an active_storage/ folder (files keyed by
# their blob key), which can be written to a local directory and/or to S3.
module BackupOperations
  extend ActiveSupport::Concern
  extend T::Sig
  extend T::Helpers

  S3_ARCHIVE_PREFIX = "full_backups/"
  LEGACY_S3_ARCHIVE_PREFIX = "db_backups/"
  STORAGE_SERVICES = {
    current: nil,
    local: "local",
    s3: "s3_host"
  }.freeze

  requires_ancestor { Kernel }

  private

  # Staging area for assembling and extracting archives, unique per service
  # instance so concurrent backup and restore operations (and parallel test
  # workers) never trample each other's files. It is removed by
  # #remove_temp_dir once the operation finishes.
  sig { returns(Pathname) }
  def temp_dir
    prefix = "run-#{Process.pid}-"
    @temp_dir ||= unique_dir(prefix, Rails.root.join("tmp/backups"))
  end

  sig { void }
  def remove_temp_dir
    return unless @temp_dir

    FileUtils.rm_rf(@temp_dir)
    @temp_dir = nil
  end

  sig { params(prefix: String, base: Pathname).returns(Pathname) }
  def unique_dir(prefix, base)
    FileUtils.mkdir_p(base)
    Pathname.new(Dir.mktmpdir(prefix, base.to_s))
  end

  sig { returns(Pathname) }
  def local_archive_dir = Rails.root.join("storage/backups")

  sig { returns(Integer) }
  def backup_retention_days = 60

  sig { params(timestamp: String).returns(String) }
  def archive_filename(timestamp) = "backup-#{timestamp}.tar.gz"

  sig { params(filename: String).returns(String) }
  def archive_s3_key(filename) = "#{S3_ARCHIVE_PREFIX}#{filename}"

  # Every file-based database configured for the current environment.
  # In-memory databases (the test suite) are skipped.
  sig { returns(T::Array[Pathname]) }
  def database_paths
    ActiveRecord::Base.configurations
      .configs_for(env_name: Rails.env)
      .filter_map { |config| database_path_for(config.database) }
  end

  sig { params(path: T.nilable(String)).returns(T.nilable(Pathname)) }
  def database_path_for(path)
    return if path.nil? || path.include?(":memory:")

    Rails.root.join(path)
  end

  sig { params(path: Pathname).returns(String) }
  def db_name_for_path(path) = path.basename.to_s

  # The local disk root of the currently active Active Storage service, or nil
  # when Active Storage is backed by S3.
  sig { returns(T.nilable(Pathname)) }
  def current_storage_root
    service = ActiveStorage::Blob.service
    return unless service.is_a?(ActiveStorage::Service::DiskService)

    Pathname.new(service.root)
  end

  # Files under the local storage root that belong to Active Storage.
  # Database files and the local backup folder are excluded.
  sig do
    params(
      storage_root: Pathname,
      archive_dir: Pathname
    ).returns(T::Array[Pathname])
  end
  def snapshot_storage_files(storage_root, archive_dir:)
    return [] unless storage_root.exist?

    storage_root.glob("**/*").filter_map do |path|
      next if path.directory?
      next if storage_file_excluded?(path, storage_root, archive_dir)

      path
    end
  end

  sig { params(timestamp: String, staging: Pathname).returns(Pathname) }
  def create_archive(timestamp, staging)
    FileUtils.mkdir_p(staging.join("db"))
    FileUtils.mkdir_p(staging.join("active_storage"))

    archive_path = temp_dir.join(archive_filename(timestamp))
    tar_args = [archive_path.to_s, "-C", staging.to_s, "db", "active_storage"]
    system("tar", "-czf", *tar_args, exception: true)
    archive_path
  end

  sig do
    params(archive_path: Pathname, extract_dir: Pathname).returns(Pathname)
  end
  def extract_archive(archive_path, extract_dir)
    FileUtils.mkdir_p(extract_dir)
    tar_args = ["-xzf", archive_path.to_s, "-C", extract_dir.to_s]
    system("tar", *tar_args, exception: true)
    extract_dir
  end

  # Online backup of a SQLite database, including any uncheckpointed WAL
  # pages, into a consistent snapshot file.
  sig { params(source: Pathname, destination: Pathname).void }
  def sqlite3_backup(source, destination)
    # sqlite3 requires the .backup command and quoted path as a single argv.
    backup_command = [".backup", "'#{destination}'"].join(" ")
    system("sqlite3", source.to_s, backup_command, exception: true)
  end

  sig { returns(String) }
  def s3_bucket = s3_env("S3_BUCKET")

  sig { returns(Aws::S3::Resource) }
  def s3_archive_resource
    @s3_archive_resource ||= Aws::S3::Resource.new(
      endpoint: s3_env("S3_ENDPOINT"),
      access_key_id: s3_env("S3_ACCESS_KEY_ID"),
      secret_access_key: s3_env("S3_SECRET_ACCESS_KEY"),
      region: ENV["S3_REGION"].presence || "us-east-1"
    )
  end

  sig { params(var: String).returns(String) }
  def s3_env(var)
    ENV[var].presence || raise("Missing #{var} environment variable")
  end

  # Streamed so the archive never has to fit into memory.
  sig { params(resource: T.untyped, key: String).returns(Pathname) }
  def download_from_s3(resource, key)
    destination = temp_dir.join(File.basename(key))
    File.open(destination, "wb") do |file|
      resource.bucket(s3_bucket).object(key).get { |chunk| file.write(chunk) }
    end
    destination
  end

  sig { params(resource: T.untyped, key: String, path: Pathname).void }
  def upload_to_s3(resource, key, path)
    File.open(path, "rb") do |io|
      resource.bucket(s3_bucket).object(key).put(body: io)
    end
  end

  sig do
    params(resource: T.untyped, prefix: String).returns(T::Array[T.untyped])
  end
  def s3_objects(resource, prefix)
    resource.bucket(s3_bucket).objects(prefix: prefix).to_a
  end

  # Resolve the storage target ("local" | "s3" | "current") to its Active
  # Storage service.
  sig do
    params(
      storage_target: T.any(String, Symbol)
    ).returns(ActiveStorage::Service)
  end
  def resolve_storage_service(storage_target)
    ActiveStorage::Blob.services.fetch(storage_service_name(storage_target))
  end

  # The Active Storage service name for the target; "current" resolves to the
  # service the app is actually configured with.
  sig do
    params(
      storage_target: T.any(String, Symbol)
    ).returns(String)
  end
  def storage_service_name(storage_target)
    name = STORAGE_SERVICES.fetch(storage_target.to_sym) do
      message = "Unknown storage target: #{storage_target}"
      raise ArgumentError, "#{message}. Use local, s3 or current."
    end
    name || ActiveStorage::Blob.service.name.to_s
  end

  # Point every restored Active Storage blob at the target service so the app
  # reads files from the place they were restored to. Applied directly to the
  # restored database file, so it works for every database in the archive.
  sig { params(db_path: Pathname, service_name: String).void }
  def update_blob_service_name(db_path, service_name)
    return unless File.exist?(db_path)

    db = SQLite3::Database.new(db_path.to_s)
    return if db.table_info("active_storage_blobs").empty?

    db.execute("UPDATE active_storage_blobs SET service_name = ?", service_name)
  ensure
    db&.close
  end

  sig do
    params(
      path: Pathname,
      storage_root: Pathname,
      archive_dir: Pathname
    ).returns(T::Boolean)
  end
  def storage_file_excluded?(path, storage_root, archive_dir)
    relative = path.relative_path_from(storage_root).to_s
    return true if relative.match?(/\.sqlite3(-wal|-shm|-journal)?\z/)

    backup_root = archive_dir.relative_path_from(storage_root).to_s
    return false if backup_root.start_with?("..")

    relative.start_with?("#{backup_root}/")
  end
end
