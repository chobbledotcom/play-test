# frozen_string_literal: true

module S3BackupOperations
  extend ActiveSupport::Concern

  private

  def backup_dir = "db_backups"

  def backup_retention_days = 60

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

    # Use array form to prevent command injection
    unless system("tar", "-czf", dest_path.to_s, "-C", dir_name.to_s, base_name.to_s, exception: true)
      error_msg = "Failed to create tar archive"
      Sentry.capture_message(error_msg, level: "error", extra: {
        command: "tar -czf #{dest_path} -C #{dir_name} #{base_name}",
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
end
