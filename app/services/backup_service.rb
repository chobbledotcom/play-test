# typed: strict
# frozen_string_literal: true

class BackupService
  extend T::Sig

  include BackupOperations

  DESTINATIONS = {
    both: %i[local s3],
    local: [:local],
    s3: [:s3]
  }.freeze

  # Create a full backup: every file-based SQLite database plus all Active
  # Storage files, stored in a single tar.gz archive. The archive can be
  # written to the local backup directory, uploaded to S3, or both.
  sig do
    params(
      destination: T.any(String, Symbol),
      db_paths: T.nilable(T::Array[Pathname]),
      storage_root: T.nilable(Pathname),
      archive_dir: T.nilable(Pathname),
      s3_resource: T.untyped
    ).returns(T::Hash[Symbol, T.untyped])
  end
  def perform(
    destination: "both",
    db_paths: nil,
    storage_root: nil,
    archive_dir: nil,
    s3_resource: nil
  )
    destinations = normalize_destination(destination)
    paths = db_paths || database_paths
    root = storage_root || current_storage_root
    local_dir = archive_dir || local_archive_dir
    raise "No databases to back up" if paths.empty? && root.nil?

    archive_path = create_full_archive(paths, root, s3_resource, local_dir)
    s3_key = distribute(archive_path, destinations, s3_resource, local_dir)
    build_result(archive_path, s3_key, destinations, local_dir)
  ensure
    FileUtils.rm_f(archive_path) if archive_path
  end

  private

  sig { params(destination: T.any(String, Symbol)).returns(T::Array[Symbol]) }
  def normalize_destination(destination)
    DESTINATIONS.fetch(destination.to_sym) do
      message = "Unknown destination: #{destination}"
      raise ArgumentError, "#{message}. Use local, s3 or both."
    end
  end

  sig do
    params(
      paths: T::Array[Pathname],
      root: T.nilable(Pathname),
      s3_resource: T.untyped,
      local_dir: Pathname
    ).returns(Pathname)
  end
  def create_full_archive(paths, root, s3_resource, local_dir)
    timestamp = Time.current.to_date.to_s
    staging = temp_archive_dir.join(timestamp)
    begin
      backup_databases(paths, staging)
      backup_storage(root, staging, s3_resource, local_dir)
      create_archive(timestamp, staging)
    ensure
      FileUtils.rm_rf(staging)
    end
  end

  # Returns the S3 key when the archive was uploaded.
  sig do
    params(
      archive_path: Pathname,
      destinations: T::Array[Symbol],
      s3_resource: T.untyped,
      local_dir: Pathname
    ).returns(T.nilable(String))
  end
  def distribute(archive_path, destinations, s3_resource, local_dir)
    copy_locally = destinations.include?(:local)
    copy_to_local_archive(archive_path, local_dir) if copy_locally

    upload_remotely = destinations.include?(:s3)
    upload_archive_to_s3(archive_path, s3_resource) if upload_remotely
  end

  sig { params(archive_path: Pathname, local_dir: Pathname).void }
  def copy_to_local_archive(archive_path, local_dir)
    FileUtils.mkdir_p(local_dir)
    FileUtils.cp(archive_path, local_dir.join(archive_path.basename))
    cleanup_old_local_archives(local_dir)
  end

  sig { params(archive_path: Pathname, s3_resource: T.untyped).returns(String) }
  def upload_archive_to_s3(archive_path, s3_resource)
    resource = s3_resource || s3_archive_resource
    key = archive_s3_key(archive_path.basename.to_s)
    upload_to_s3(resource, key, archive_path)
    cleanup_old_s3_archives(resource)
    key
  end

  sig { params(paths: T::Array[Pathname], staging: Pathname).void }
  def backup_databases(paths, staging)
    db_dir = staging.join("db")
    FileUtils.mkdir_p(db_dir)
    paths.each do |db_path|
      sqlite3_backup(db_path, db_dir.join(db_name_for_path(db_path)))
    end
  end

  sig do
    params(
      root: T.nilable(Pathname),
      staging: Pathname,
      s3_resource: T.untyped,
      local_dir: Pathname
    ).void
  end
  def backup_storage(root, staging, s3_resource, local_dir)
    FileUtils.mkdir_p(staging.join("active_storage"))
    return backup_s3_storage(staging, s3_resource) if root.nil?

    snapshot_storage_files(root, archive_dir: local_dir).each do |file|
      FileUtils.cp(file, staging.join("active_storage", file.basename))
    end
  end

  # When Active Storage is backed by S3, snapshot every object in the bucket
  # except previous backups. Files are keyed by their blob key.
  sig { params(staging: Pathname, s3_resource: T.untyped).void }
  def backup_s3_storage(staging, s3_resource)
    resource = s3_resource || s3_archive_resource
    archive_prefixes = [S3_ARCHIVE_PREFIX, LEGACY_S3_ARCHIVE_PREFIX]
    keys = s3_objects(resource, "").map(&:key)
    blobs = keys.reject { it.start_with?(*archive_prefixes) }

    blobs.each do |key|
      content = resource.bucket(s3_bucket).object(key).get.body.read
      File.binwrite(staging.join("active_storage", File.basename(key)), content)
    end
  end

  sig { params(local_dir: Pathname).void }
  def cleanup_old_local_archives(local_dir)
    cutoff = Time.current - backup_retention_days.days
    local_dir.glob("backup-*.tar.gz").each do |path|
      FileUtils.rm_f(path) if path.mtime < cutoff
    end
  end

  sig { params(resource: T.untyped).void }
  def cleanup_old_s3_archives(resource)
    cutoff = Time.current - backup_retention_days.days
    objects = s3_objects(resource, S3_ARCHIVE_PREFIX)
    objects.each do |object|
      next unless object.key.match?(/backup-\d{4}-\d{2}-\d{2}\.tar\.gz\z/)

      expired = object.last_modified < cutoff
      resource.bucket(s3_bucket).object(object.key).delete if expired
    end
  end

  sig do
    params(
      archive_path: Pathname,
      s3_key: T.nilable(String),
      destinations: T::Array[Symbol],
      local_dir: Pathname
    ).returns(T::Hash[Symbol, T.untyped])
  end
  def build_result(archive_path, s3_key, destinations, local_dir)
    filename = archive_path.basename.to_s
    size_mb = (archive_path.size / 1024.0 / 1024.0).round(2)

    {
      filename: filename,
      destination: destinations.join(", "),
      location: s3_key || local_dir.join(filename).to_s,
      size_mb: size_mb
    }
  end
end
