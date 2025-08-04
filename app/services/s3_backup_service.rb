# frozen_string_literal: true

class S3BackupService
  include S3Helpers

  def perform
    ensure_s3_enabled
    validate_s3_config

    handle_s3_errors do
      # Capture backup context for better error reporting
      Sentry.with_scope do |scope|
        scope.set_context("backup", {
          service: "S3BackupService",
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
        log_info "Creating database backup..."

        # Check if database path exists and is valid
        unless database_path && File.exist?(database_path)
          error_msg = "Database file not found at: #{database_path}"
          log_error error_msg
          Sentry.capture_message(error_msg, level: "error")
          raise error_msg
        end

        # Check if sqlite3 command is available
        unless system("which sqlite3 > /dev/null 2>&1")
          error_msg = "sqlite3 command not found - required for database backup"
          log_error error_msg
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
        log_info "Database backup created successfully"

        # Compress the backup
        log_info "Compressing backup..."
        create_tar_gz(temp_backup_path, temp_compressed_path)
        log_info "Backup compressed successfully"

        # Upload to S3
        log_info "Uploading to S3 (#{s3_key})..."
        File.open(temp_compressed_path, "rb") do |file|
          service.upload(s3_key, file)
        end
        log_info "Backup uploaded to S3 successfully"

        # Clean up old backups
        log_info "Cleaning up old backups..."
        deleted_count = cleanup_old_backups(service)
        log_info "Deleted #{deleted_count} old backups" if deleted_count.positive?

        backup_size_mb = (File.size(temp_compressed_path) / 1024.0 / 1024.0).round(2)
        log_info "Database backup completed successfully!"
        log_info "Backup location: #{s3_key}"
        log_info "Backup size: #{backup_size_mb} MB"

        # Return summary for callers
        {
          success: true,
          location: s3_key,
          size_mb: backup_size_mb,
          deleted_count: deleted_count
        }
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

    deleted_count
  end

  # Logging helpers that work for both rake tasks and jobs
  def log_info(message)
    if defined?(Rails.logger)
      Rails.logger.info message
    else
      puts message
    end
  end

  def log_error(message)
    if defined?(Rails.logger)
      Rails.logger.error message
    else
      puts "❌ #{message}"
    end
  end
end