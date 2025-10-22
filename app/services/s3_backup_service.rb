# typed: strict
# frozen_string_literal: true

class S3BackupService
  extend T::Sig

  include S3Helpers
  include S3BackupOperations

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def perform
    ensure_s3_enabled
    validate_s3_config

    service = get_s3_service
    FileUtils.mkdir_p(temp_dir)

    timestamp = Time.current.strftime("%Y-%m-%d")
    backup_filename = "database-#{timestamp}.sqlite3"
    temp_backup_path = temp_dir.join(backup_filename)
    s3_key = "#{backup_dir}/database-#{timestamp}.tar.gz"

    # Create SQLite backup
    Rails.logger.info "Creating database backup..."
    system("sqlite3", database_path.to_s, ".backup '#{temp_backup_path}'", exception: true)
    Rails.logger.info "Database backup created successfully"

    # Compress the backup
    Rails.logger.info "Compressing backup..."
    temp_compressed_path = create_tar_gz(timestamp)
    Rails.logger.info "Backup compressed successfully"

    # Upload to S3
    Rails.logger.info "Uploading to S3 (#{s3_key})..."
    File.open(temp_compressed_path, "rb") do |file|
      service.upload(s3_key, file)
    end
    Rails.logger.info "Backup uploaded to S3 successfully"

    # Clean up old backups
    Rails.logger.info "Cleaning up old backups..."
    deleted_count = cleanup_old_backups(service)
    Rails.logger.info "Deleted #{deleted_count} old backups" if deleted_count.positive?

    backup_size_mb = (File.size(temp_compressed_path) / 1024.0 / 1024.0).round(2)
    Rails.logger.info "Database backup completed successfully!"
    Rails.logger.info "Backup location: #{s3_key}"
    Rails.logger.info "Backup size: #{backup_size_mb} MB"

    {
      success: true,
      location: s3_key,
      size_mb: backup_size_mb,
      deleted_count: deleted_count
    }
  ensure
    FileUtils.rm_f(temp_backup_path) if defined?(temp_backup_path)
    FileUtils.rm_f(temp_dir.join("database-#{timestamp}.tar.gz")) if defined?(timestamp)
  end
end
