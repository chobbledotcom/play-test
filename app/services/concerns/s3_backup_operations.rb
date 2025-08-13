# typed: false
# frozen_string_literal: true

module S3BackupOperations
  extend ActiveSupport::Concern

  private

  def backup_dir = "db_backups"

  def backup_retention_days = 60

  def temp_dir = Rails.root.join("tmp/backups")

  def database_path
    db_config = Rails.configuration.database_configuration[Rails.env]

    # Handle multi-database configuration
    db_config = db_config["primary"] if db_config.is_a?(Hash) && db_config.key?("primary")

    raise "Database not configured for #{Rails.env}" unless db_config["database"]

    path = db_config["database"]
    path.start_with?("/") ? path : Rails.root.join(path)
  end

  def create_tar_gz(timestamp)
    backup_filename = "database-#{timestamp}.sqlite3"
    compressed_filename = "database-#{timestamp}.tar.gz"
    source_path = temp_dir.join(backup_filename)
    dest_path = temp_dir.join(compressed_filename)

    dir_name = File.dirname(source_path)
    base_name = File.basename(source_path)

    system("tar", "-czf", dest_path.to_s, "-C", dir_name.to_s,
      base_name.to_s, exception: true)

    dest_path
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
