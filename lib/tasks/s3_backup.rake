# frozen_string_literal: true

require "fileutils"
require "zlib"
require "rubygems/package"

namespace :s3 do
  namespace :backup do
    def backup_dir = "db_backups"

    def temp_dir = Rails.root.join("tmp/backups")

    def database_path = Rails.root.join(Rails.configuration.database_configuration[Rails.env]["database"])

    def backup_retention_days = 60

    desc "Backup SQLite database to S3"
    task database: :environment do
      ensure_s3_enabled

      handle_s3_errors do
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
          print "Creating database backup... "
          system("sqlite3 #{database_path} \".backup '#{temp_backup_path}'\"", exception: true)
          puts "✅"

          # Compress the backup
          print "Compressing backup... "
          create_tar_gz(temp_backup_path, temp_compressed_path)
          puts "✅"

          # Upload to S3
          print "Uploading to S3 (#{s3_key})... "
          File.open(temp_compressed_path, "rb") do |file|
            service.upload(s3_key, file)
          end
          puts "✅"

          # Clean up old backups
          print "Cleaning up old backups... "
          cleanup_old_backups(service)
          puts "✅"

          puts "\n🎉 Database backup completed successfully!"
          puts "   Backup location: #{s3_key}"
          puts "   Backup size: #{(File.size(temp_compressed_path) / 1024.0 / 1024.0).round(2)} MB"
        ensure
          # Clean up temp files
          FileUtils.rm_f(temp_backup_path)
          FileUtils.rm_f(temp_compressed_path)
        end
      end
    end

    desc "List database backups in S3"
    task list: :environment do
      ensure_s3_enabled

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

      unless args[:date]
        puts "❌ Please provide a date in YYYY-MM-DD format"
        puts "   Example: rake s3:backup:download[2025-07-31]"
        exit 1
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
          exit 1
        end
      end
    end

    private

    def create_tar_gz(source_path, dest_path)
      # Use system tar command for reliable compression
      system("tar -czf #{dest_path} -C #{File.dirname(source_path)} #{File.basename(source_path)}", exception: true)
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

      print "(deleted #{deleted_count} old backups) " if deleted_count.positive?
    end
  end
end
