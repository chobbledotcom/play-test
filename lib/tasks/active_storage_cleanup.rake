namespace :active_storage do
  desc "Clean up orphaned Active Storage files (files without database records)"
  task cleanup_orphaned: :environment do
    storage_path = Rails.root.join("tmp/storage")

    unless Dir.exist?(storage_path)
      puts "No storage directory found at #{storage_path}"
      next
    end

    # Get all blob keys from database
    blob_keys = ActiveStorage::Blob.pluck(:key).to_set
    puts "Found #{blob_keys.size} blobs in database"

    # Find all files on disk
    orphaned_count = 0
    orphaned_size = 0

    Dir.glob(File.join(storage_path, "**/*")).each do |path|
      next if File.directory?(path)

      # Extract key from path (last component of the path)
      key = File.basename(path)

      unless blob_keys.include?(key)
        orphaned_count += 1
        orphaned_size += File.size(path)

        if ENV["DRY_RUN"] != "false"
          puts "Would delete: #{path} (#{File.size(path)} bytes)"
        else
          File.delete(path)
          puts "Deleted: #{path}"
        end
      end
    end

    # Clean up empty directories
    Dir.glob(File.join(storage_path, "**/*")).reverse_each do |path|
      next unless File.directory?(path)
      next unless Dir.empty?(path)

      if ENV["DRY_RUN"] != "false"
        puts "Would remove empty directory: #{path}"
      else
        Dir.rmdir(path)
        puts "Removed empty directory: #{path}"
      end
    end

    puts "\nSummary:"
    puts "Orphaned files: #{orphaned_count}"
    mb_size = orphaned_size / 1024.0 / 1024.0
    puts "Total size: #{"%.2f" % mb_size} MB"

    if ENV["DRY_RUN"] != "false"
      puts "\nThis was a dry run. To actually delete files, run:"
      puts "  DRY_RUN=false bundle exec rake active_storage:cleanup_orphaned"
    end
  end

  desc "Show Active Storage disk usage statistics"
  task stats: :environment do
    storage_path = Rails.root.join("tmp/storage")

    unless Dir.exist?(storage_path)
      puts "No storage directory found at #{storage_path}"
      next
    end

    # Database stats
    blob_count = ActiveStorage::Blob.count
    db_total_size = ActiveStorage::Blob.sum(:byte_size)

    # Disk stats
    disk_files = Dir.glob(File.join(storage_path, "**/*")).reject { |f| File.directory?(f) }
    disk_count = disk_files.size
    disk_size = disk_files.sum { |f| File.size(f) }

    # Find duplicates by checksum
    duplicates = ActiveStorage::Blob.group(:checksum).having("COUNT(*) > 1").count

    puts "Database Statistics:"
    puts "  Total blobs: #{blob_count}"
    puts "  Total size: #{"%.2f" % (db_total_size / 1024.0 / 1024.0)} MB"
    puts "  Duplicate checksums: #{duplicates.size}"

    puts "\nDisk Statistics:"
    puts "  Total files: #{disk_count}"
    puts "  Total size: #{"%.2f" % (disk_size / 1024.0 / 1024.0)} MB"

    orphaned = disk_count - blob_count
    if orphaned > 0
      puts "\nOrphaned files: #{orphaned}"
      puts "Run 'rake active_storage:cleanup_orphaned' to clean up"
    end
  end
end
