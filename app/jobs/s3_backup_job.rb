# frozen_string_literal: true

class S3BackupJob < ApplicationJob
  queue_as :default

  def perform
    # Ensure Rails is fully loaded for background jobs
    Rails.application.eager_load! if Rails.env.production?

    ensure_s3_enabled
    validate_s3_config

    handle_s3_errors do
      # Capture backup context for better error reporting
      Sentry.with_scope do |scope|
        scope.set_context("backup", {
          job: "S3BackupJob",
          rails_env: Rails.env,
          timestamp: Time.current.iso8601
        })
      end

      service = get_s3_service

      # Create temp directory
      FileUtils.mkdir_p(temp_dir)

      # Generate backup filename
      timestamp = Time.current.strftime("%Y-%m-%d")
      backup_filename = "database-#{timestamp}.sqlite3"
      compressed_filename = "database-#{timestamp}.tar.gz"
      temp_backup_path = temp_dir.join(backup_filename)
      temp_compressed_path = temp_dir.join(compressed_filename)
      s3_key = "#{backup_dir}/#{compressed_filename}"

      begin
        # Create SQLite backup
        Rails.logger.info "Creating database backup..."

        # Check if database path exists and is valid
        unless database_path && File.exist?(database_path)
          error_msg = "Database file not found at: #{database_path}"
          Rails.logger.error error_msg
          Sentry.capture_message(error_msg, level: "error")
          raise error_msg
        end

        # Check if sqlite3 command is available
        unless system("which sqlite3 > /dev/null 2>&1")
          error_msg = "sqlite3 command not found - required for database backup"
          Rails.logger.error error_msg
          Sentry.capture_message(error_msg, level: "error", extra: {
            environment: Rails.env,
            path: ENV["PATH"]
          })
          raise error_msg
        end

        backup_command = "sqlite3 #{database_path} \".backup '#{temp_backup_path}'\""
        unless system(backup_command, exception: true)
          error_msg = "Failed to create SQLite backup"
          Sentry.capture_message(error_msg, level: "error", extra: {
            command: backup_command,
            database_path: database_path.to_s,
            temp_backup_path: temp_backup_path.to_s
          })
          raise error_msg
        end
        Rails.logger.info "Database backup created successfully"

        # Compress the backup
        Rails.logger.info "Compressing backup..."
        create_tar_gz(temp_backup_path, temp_compressed_path)
        Rails.logger.info "Backup compressed successfully"

        # Upload to S3
        Rails.logger.info "Uploading to S3 (#{s3_key})..."
        File.open(temp_compressed_path, "rb") do |file|
          service.upload(s3_key, file)
        end
        Rails.logger.info "Backup uploaded to S3 successfully"

        # Clean up old backups
        Rails.logger.info "Cleaning up old backups..."
        cleanup_old_backups(service)
        Rails.logger.info "Old backups cleaned up successfully"

        Rails.logger.info "Database backup completed successfully!"
        Rails.logger.info "Backup location: #{s3_key}"
        Rails.logger.info "Backup size: #{(File.size(temp_compressed_path) / 1024.0 / 1024.0).round(2)} MB"
      rescue => e
        # Report any unexpected errors to Sentry with full context
        Sentry.capture_exception(e, extra: {
          database_path: database_path.to_s,
          backup_filename: backup_filename,
          s3_key: s3_key,
          step: "backup_process"
        })
        raise # Re-raise to let handle_s3_errors deal with it
      ensure
        # Clean up temp files
        FileUtils.rm_f(temp_backup_path)
        FileUtils.rm_f(temp_compressed_path)
      end
    end
  end

  private

  def backup_dir = "db_backups"

  def temp_dir
    unless Rails.root
      error_msg = "Rails.root is nil - cannot determine temp directory"
      Sentry.capture_message(error_msg, level: "error")
      raise error_msg
    end
    Rails.root.join("tmp/backups")
  end

  def database_path
    db_config = Rails.configuration.database_configuration[Rails.env]
    unless db_config && db_config["database"]
      error_msg = "Database configuration missing for #{Rails.env} environment"
      Sentry.capture_message(error_msg, level: "error", extra: {
        rails_env: Rails.env,
        db_config: db_config
      })
      raise error_msg
    end

    path = db_config["database"]
    # Handle relative paths
    path = Rails.root.join(path) unless path.start_with?("/")
    path
  end

  def backup_retention_days = 60

  def create_tar_gz(source_path, dest_path)
    # Check if tar command is available
    unless system("which tar > /dev/null 2>&1")
      error_msg = "tar command not found - required for backup compression"
      Sentry.capture_message(error_msg, level: "error", extra: {
        environment: Rails.env,
        path: ENV["PATH"]
      })
      raise error_msg
    end

    # Use system tar command for reliable compression
    dir_name = File.dirname(source_path)
    base_name = File.basename(source_path)
    tar_command = "tar -czf #{dest_path} -C #{dir_name} #{base_name}"

    unless system(tar_command, exception: true)
      error_msg = "Failed to create tar archive"
      Sentry.capture_message(error_msg, level: "error", extra: {
        command: tar_command,
        source_path: source_path,
        dest_path: dest_path
      })
      raise error_msg
    end
  end

  def cleanup_old_backups(service)
    bucket = service.send(:bucket)
    cutoff_date = Time.current - backup_retention_days.days
    deleted_count = 0

    bucket.objects(prefix: "#{backup_dir}/").each do |object|
      next unless object.key.match?(/database-\d{4}-\d{2}-\d{2}\.tar\.gz$/)

      if object.last_modified < cutoff_date
        service.delete(object.key)
        deleted_count += 1
      end
    end

    Rails.logger.info "Deleted #{deleted_count} old backups" if deleted_count.positive?
  end

  # Helper methods from rake task
  def ensure_s3_enabled
    return if ENV["USE_S3_STORAGE"] == "true"

    error_msg = "S3 storage is not enabled. Set USE_S3_STORAGE=true in your .env file"
    Rails.logger.error error_msg
    raise error_msg
  end

  def validate_s3_config
    required_vars = %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET]
    missing_vars = required_vars.select { |var| ENV[var].blank? }

    if missing_vars.any?
      error_msg = "Missing required S3 environment variables: #{missing_vars.join(", ")}"
      Rails.logger.error error_msg

      Sentry.capture_message(error_msg, level: "error", extra: {
        missing_vars: missing_vars,
        job: "S3BackupJob",
        environment: Rails.env
      })

      raise error_msg
    end
  end

  def get_s3_service
    service = ActiveStorage::Blob.service

    unless service.is_a?(ActiveStorage::Service::S3Service)
      error_msg = "Active Storage is not configured to use S3. Current service: #{service.class.name}"
      Rails.logger.error error_msg
      raise error_msg
    end

    service
  end

  def handle_s3_errors
    yield
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error "S3 Error: #{e.message}"
    Sentry.capture_exception(e)
    raise
  rescue => e
    Rails.logger.error "Unexpected error: #{e.message}"
    Sentry.capture_exception(e)
    raise
  end
end