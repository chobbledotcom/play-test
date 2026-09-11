# typed: strict
# frozen_string_literal: true

class RestoreService
  extend T::Sig

  include BackupOperations

  # Restore a full backup (database + Active Storage files).
  #
  # date           - the backup date in YYYY-MM-DD format
  # storage_target - where Active Storage files are restored to:
  #                  "local" (disk), "s3" (object storage) or "current"
  #                  (the service the app is currently using)
  # service_name   - when migrating storage, the Active Storage service name
  #                  blobs in the restored database are pointed at
  sig do
    params(
      date: String,
      storage_target: T.any(String, Symbol),
      service_name: T.nilable(String),
      db_paths: T.nilable(T::Array[Pathname]),
      archive_dir: T.nilable(Pathname),
      storage_service: T.untyped,
      s3_resource: T.untyped
    ).returns(T::Hash[Symbol, T.untyped])
  end
  def perform(
    date:,
    storage_target: "current",
    service_name: nil,
    db_paths: nil,
    archive_dir: nil,
    storage_service: nil,
    s3_resource: nil
  )
    validate_date!(date)
    paths = db_paths || database_paths
    service, name = targets(storage_target, service_name, storage_service)
    local_dir = archive_dir || local_archive_dir
    filename = archive_filename(date)
    archive_path, location = locate_archive(local_dir, filename, s3_resource)
    restored = restore_archive(archive_path, date, paths, service, name)
    build_result(filename, location, restored, name, snapshot_dir)
  ensure
    remove_temp_dir
  end

  private

  # Find the archive locally first, then fall back to downloading it from S3.
  sig do
    params(
      local_dir: Pathname,
      filename: String,
      s3_resource: T.untyped
    ).returns([Pathname, String])
  end
  def locate_archive(local_dir, filename, s3_resource)
    local_path = local_dir.join(filename)
    return [local_path, local_path.to_s] if local_path.exist?

    resource = s3_resource || s3_archive_resource
    key = archive_s3_key(filename)
    archive_path = download_from_s3(resource, key)
    bucket = s3_bucket
    [archive_path, "s3://#{bucket}/#{key}"]
  rescue Aws::S3::Errors::NoSuchKey
    bucket = s3_bucket
    raise "#{filename} not found in #{local_dir} or in S3 bucket #{bucket}"
  end

  sig do
    params(
      archive_path: Pathname,
      date: String,
      paths: T::Array[Pathname],
      target_service: T.untyped,
      target_name: String
    ).returns(T::Array[String])
  end
  def restore_archive(archive_path, date, paths, target_service, target_name)
    staging = temp_dir.join("restore-#{date}")
    begin
      extract_archive(archive_path, staging)
      backup_database_snapshots(paths)
      restored = restore_databases(staging, paths)
      restore_storage(staging, target_service)
      update_blob_service_names(paths, target_name)
      restored
    ensure
      FileUtils.rm_rf(staging)
      downloaded = archive_path.to_s.start_with?(temp_dir.to_s)
      FileUtils.rm_f(archive_path) if downloaded
    end
  end

  sig { params(date: String).void }
  def validate_date!(date)
    return if date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    raise ArgumentError, "Invalid backup date: #{date}. Expected YYYY-MM-DD."
  end

  sig do
    params(
      storage_target: T.any(String, Symbol),
      service_name: T.nilable(String),
      storage_service: T.untyped
    ).returns([T.untyped, String])
  end
  def targets(storage_target, service_name, storage_service)
    service = storage_service || resolve_storage_service(storage_target)
    name = service_name || storage_service_name(storage_target)
    [service, name]
  end

  sig { params(paths: T::Array[Pathname]).void }
  def backup_database_snapshots(paths)
    FileUtils.mkdir_p(snapshot_dir)
    paths.each do |db_path|
      next unless File.exist?(db_path)

      sqlite3_backup(db_path, snapshot_path(db_path))
    end
  end

  sig do
    params(
      staging: Pathname,
      paths: T::Array[Pathname]
    ).returns(T::Array[String])
  end
  def restore_databases(staging, paths)
    staging.glob("db/*").map do |file|
      name = file.basename.to_s
      target = paths.find { |path| db_name_for_path(path) == name }
      raise unmatched_database_error(name) if target.nil?

      FileUtils.mkdir_p(target.dirname)
      remove_database_sidecars(target)
      FileUtils.cp(file, target)
      name
    end
  end

  # Stale WAL/journal sidecars from the pre-restore database would otherwise be
  # replayed over the restored file, so drop them first.
  sig { params(db_path: Pathname).void }
  def remove_database_sidecars(db_path)
    base = db_path.to_s
    sidecars = ["#{base}-wal", "#{base}-shm", "#{base}-journal"]
    FileUtils.rm_f(Dir.glob(sidecars))
  end

  # Files nest under active_storage in the shape of their blob keys, so
  # uploads use the full key, not just the basename.
  sig { params(staging: Pathname, target_service: T.untyped).void }
  def restore_storage(staging, target_service)
    files_root = staging.join("active_storage")
    files_root.glob("**/*").each do |file|
      next if file.directory?

      key = file.relative_path_from(files_root).to_s
      File.open(file, "rb") do |io|
        target_service.upload(key, io)
      end
    end
  end

  sig { params(paths: T::Array[Pathname], service_name: String).void }
  def update_blob_service_names(paths, service_name)
    paths.each { update_blob_service_name(it, service_name) }
  end

  sig { params(db_path: Pathname).returns(Pathname) }
  def snapshot_path(db_path)
    suffix = Time.current.strftime("%Y%m%d%H%M%S")
    name = db_name_for_path(db_path)
    filename = "#{name}.#{suffix}.pre-restore"
    snapshot_dir.join(filename)
  end

  # Safety snapshots must survive the restore, so they live outside the
  # staging directory that remove_temp_dir cleans up. The own-process prefix
  # lets the test suite clean up only its own snapshots, never another
  # parallel worker's.
  sig { returns(Pathname) }
  def snapshot_dir
    @snapshot_dir ||= unique_dir(
      "restore-#{Process.pid}-",
      Rails.root.join("tmp/backups/snapshots")
    )
  end

  sig { params(name: String).returns(String) }
  def unmatched_database_error(name)
    environment = Rails.env
    message = "Backup contains #{name}, which has no matching database in"
    "#{message} #{environment}. Pass db_paths to restore it."
  end

  sig do
    params(
      filename: String,
      location: String,
      restored: T::Array[String],
      target_name: String,
      snapshots_dir: Pathname
    ).returns(T::Hash[Symbol, T.untyped])
  end
  def build_result(filename, location, restored, target_name, snapshots_dir)
    {
      filename: filename,
      location: location,
      storage_target: target_name,
      snapshots_dir: snapshots_dir.to_s,
      restored_databases: restored
    }
  end
end
