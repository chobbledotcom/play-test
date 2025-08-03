# frozen_string_literal: true

require "fileutils"
require "zlib"
require "rubygems/package"

namespace :s3 do
  namespace :backup do
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
      # Handle relative paths - ensure we use Pathname for proper joining
      if path.start_with?("/")
        Pathname.new(path)
      else
        Rails.root.join(path)
      end
    end

    def backup_retention_days = 60

    desc "Backup SQLite database to S3"
    task database: :environment do
      # Ensure Rails is fully loaded
      Rails.application.eager_load!
      
      ensure_s3_enabled
      validate_s3_config

      handle_s3_errors do
        # Capture backup context for better error reporting
        Sentry.with_scope do |scope|
          scope.set_context("backup", {
            task: "s3:backup:database",
            rails_env: Rails.env,
            timestamp: Time.current.iso8601,
            working_dir: Dir.pwd,
            rails_root: Rails.root.to_s
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
          print "Creating database backup... "

          # Check if database path exists and is valid
          db_path = database_path.to_s
          
          # Log database path information for debugging
          puts "Database path: #{db_path}" if ENV["DEBUG_CRON"]
          
          unless db_path.present? && File.exist?(db_path)
            # Try alternative common production paths
            alternative_paths = [
              "/rails/storage/production.sqlite3",
              Rails.root.join("db/production.sqlite3").to_s,
              ENV["DATABASE_PATH"]
            ].compact.uniq
            
            found_path = alternative_paths.find { |path| path && File.exist?(path) }
            
            if found_path
              puts "Warning: Database not found at configured path, using: #{found_path}"
              db_path = found_path
            else
              error_msg = "Database file not found at: #{db_path}"
              puts "\n❌ #{error_msg}"
              puts "Searched paths: #{([db_path] + alternative_paths).join(', ')}"
              
              # Add detailed debugging information for cron issues
              Sentry.capture_message(error_msg, level: "error", extra: {
                database_path: db_path,
                rails_root: Rails.root.to_s,
                rails_env: Rails.env,
                working_dir: Dir.pwd,
                path_exists: File.exist?(db_path).to_s,
                db_config: Rails.configuration.database_configuration[Rails.env],
                alternative_paths: alternative_paths,
                storage_contents: Dir.exist?(Rails.root.join("storage")) ? 
                  Dir.entries(Rails.root.join("storage")).reject { |f| f.start_with?(".") } : 
                  "storage dir not found"
              })
              exit 1
            end
          end

          # Check if sqlite3 command is available
          unless system("which sqlite3 > /dev/null 2>&1")
            error_msg = "sqlite3 command not found - required for database backup"
            puts "\n❌ #{error_msg}"
            Sentry.capture_message(error_msg, level: "error", extra: {
              environment: Rails.env,
              path: ENV["PATH"]
            })
            exit 1
          end

          backup_command = "sqlite3 #{db_path} \".backup '#{temp_backup_path}'\""
          unless system(backup_command, exception: true)
            error_msg = "Failed to create SQLite backup"
            Sentry.capture_message(error_msg, level: "error", extra: {
              command: backup_command,
              database_path: db_path,
              temp_backup_path: temp_backup_path.to_s
            })
            raise error_msg
          end
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

    desc "Restore database from S3 backup"
    task :restore, [:date] => :environment do |_task, args|
      ensure_s3_enabled
      validate_s3_config

      unless args[:date]
        puts "❌ Please provide a date in YYYY-MM-DD format"
        puts "   Example: rake s3:backup:restore[2025-07-31]"
        exit 1
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
            puts "❌ Extracted database file not found at #{temp_backup_path}"
            exit 1
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
          exit 1
        ensure
          # Clean up temp files
          FileUtils.rm_f(temp_compressed_path)
          FileUtils.rm_f(temp_backup_path)
        end
      end
    end

    private

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

      print "(deleted #{deleted_count} old backups) " if deleted_count.positive?
    end
  end
end
