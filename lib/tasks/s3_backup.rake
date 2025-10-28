# typed: false
# frozen_string_literal: true

require "fileutils"
require "zlib"
require "rubygems/package"
require_relative "../../lib/s3_rake_helpers"

namespace :s3 do
  namespace :backup do
    # Include the shared S3 rake helpers
    extend S3RakeHelpers

    desc "Backup SQLite database to S3 (via job queue)"
    task database: :environment do
      # Ensure Rails is fully loaded for cron jobs
      Rails.application.eager_load! if Rails.env.production?

      puts "Enqueuing S3 backup job..."
      S3BackupJob.perform_later
      puts "✅ S3 backup job enqueued successfully!"
    end

    desc "Backup SQLite database to S3 (immediate execution)"
    task database_now: :environment do
      # Ensure Rails is fully loaded for cron jobs
      Rails.application.eager_load! if Rails.env.production?

      print "Creating database backup... "
      result = S3BackupService.new.perform
      puts "✅"

      puts "\n🎉 Database backup completed successfully!"
      puts "   Backup location: #{result[:location]}"
      puts "   Backup size: #{result[:size_mb]} MB"
      puts "   Deleted old backups: #{result[:deleted_count]}" if result[:deleted_count].positive?
    rescue => e
      puts "\n❌ Backup failed: #{e.message}"
      raise
    end

    desc "List database backups in S3"
    task list: :environment do
      ensure_s3_enabled
      validate_s3_config

      handle_s3_errors do
        service = get_s3_service
        bucket = service.send(:bucket)

        puts "Database backups in S3:"
        puts "=" * 50

        backups = []
        bucket.objects(prefix: "#{backup_dir}/").each do |object|
          next unless object.key.match?(/database-\d{4}-\d{2}-\d{2}\.tar\.gz$/)

          backups << {
            key: object.key,
            size: object.size,
            last_modified: object.last_modified
          }
        end

        if backups.empty?
          puts "No backups found."
        else
          backups.sort_by { |b| b[:last_modified] }.reverse_each do |backup|
            size_mb = (backup[:size] / 1024.0 / 1024.0).round(2)
            puts "📁 #{backup[:key].split("/").last} (#{size_mb} MB) - #{backup[:last_modified].strftime("%Y-%m-%d %H:%M:%S")}"
          end
        end

        puts "=" * 50
        puts "Total backups: #{backups.size}"
      end
    end

    desc "Download a database backup from S3"
    task :download, [:date] => :environment do |_task, args|
      ensure_s3_enabled
      validate_s3_config

      unless args[:date]
        error_msg = "Please provide a date in YYYY-MM-DD format"
        puts "❌ #{error_msg}"
        puts "   Example: rake s3:backup:download[2025-07-31]"
        raise ArgumentError, error_msg
      end

      handle_s3_errors do
        service = get_s3_service

        filename = "database-#{args[:date]}.tar.gz"
        s3_key = "#{backup_dir}/#{filename}"
        download_path = Rails.root.join("tmp", filename)

        print "Downloading #{s3_key}... "
        begin
          content = service.download(s3_key)
          File.binwrite(download_path, content)
          puts "✅"

          puts "\n📥 Backup downloaded successfully!"
          puts "   Location: #{download_path}"
          puts "   Size: #{(File.size(download_path) / 1024.0 / 1024.0).round(2)} MB"
        rescue Aws::S3::Errors::NoSuchKey
          puts "❌"
          puts "\n⚠️  Backup not found: #{filename}"
          puts "   Run 'rake s3:backup:list' to see available backups"
          raise
        end
      end
    end

    desc "Restore database from S3 backup"
    task :restore, [:date] => :environment do |_task, args|
      ensure_s3_enabled
      validate_s3_config

      unless args[:date]
        error_msg = "Please provide a date in YYYY-MM-DD format"
        puts "❌ #{error_msg}"
        puts "   Example: rake s3:backup:restore[2025-07-31]"
        raise ArgumentError, error_msg
      end

      handle_s3_errors do
        service = get_s3_service

        filename = "database-#{args[:date]}.tar.gz"
        s3_key = "#{backup_dir}/#{filename}"
        temp_compressed_path = temp_dir.join(filename)
        temp_backup_path = temp_dir.join("database-#{args[:date]}.sqlite3")

        # Create temp directory
        FileUtils.mkdir_p(temp_dir)

        begin
          # Download backup
          print "Downloading backup from S3... "
          content = service.download(s3_key)
          File.binwrite(temp_compressed_path, content)
          puts "✅"

          # Extract backup
          print "Extracting backup... "
          system("tar -xzf #{temp_compressed_path} -C #{temp_dir}", exception: true)
          puts "✅"

          # Verify extracted file exists
          unless File.exist?(temp_backup_path)
            error_msg = "Extracted database file not found at #{temp_backup_path}"
            puts "❌ #{error_msg}"
            raise StandardError, error_msg
          end

          # Create a safety backup of current database
          safety_backup_path = database_path.to_s + ".pre-restore-#{Time.current.strftime("%Y%m%d%H%M%S")}"
          print "Creating safety backup of current database... "
          FileUtils.cp(database_path, safety_backup_path) if File.exist?(database_path)
          puts "✅"

          # Restore the database
          print "Restoring database... "
          system("sqlite3 #{database_path} \".restore '#{temp_backup_path}'\"", exception: true)
          puts "✅"

          puts "\n🎉 Database restored successfully!"
          puts "   Restored from: #{filename}"
          puts "   Safety backup: #{safety_backup_path}"
          puts "\n⚠️  Remember to restart your Rails app to pick up the restored database!"
        rescue Aws::S3::Errors::NoSuchKey
          puts "❌"
          puts "\n⚠️  Backup not found: #{filename}"
          puts "   Run 'rake s3:backup:list' to see available backups"
          raise
        ensure
          # Clean up temp files
          FileUtils.rm_f(temp_compressed_path)
          FileUtils.rm_f(temp_backup_path)
        end
      end
    end
  end
end
