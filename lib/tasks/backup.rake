# typed: false
# frozen_string_literal: true

namespace :backup do
  desc "Create a full backup (database + Active Storage). Usage: rake backup:create[local|s3|both] (default: both)"
  task :create, [:destination] => :environment do |_task, args|
    destination = args.fetch(:destination, "both")

    print "Creating full backup (destination: #{destination})... "
    result = BackupService.new.perform(destination:)
    puts "✅"

    puts "\n🎉 Full backup completed successfully!"
    puts "   Backup file: #{result[:filename]}"
    puts "   Destination: #{result[:destination]}"
    puts "   Backup location: #{result[:location]}"
    puts "   Backup size: #{result[:size_mb]} MB"
  rescue => e
    puts "\n❌ Backup failed: #{e.message}"
    raise
  end

  desc "Restore a full backup. Usage: rake backup:restore[2026-09-11,local|s3|current] (storage target default: current)"
  task :restore, [:date, :storage_target] => :environment do |_task, args|
    date = args.fetch(:date)
    storage_target = args.fetch(:storage_target, "current")

    print "Restoring backup #{date} (storage target: #{storage_target})... "
    result = RestoreService.new.perform(date:, storage_target:)
    puts "✅"

    puts "\n🎉 Backup restored successfully!"
    puts "   Restored from: #{result[:location]}"
    puts "   Restored databases: #{result[:restored_databases].join(", ")}"
    puts "   Storage target: #{result[:storage_target]}"
    puts "   Safety snapshots kept in tmp/backups/pre-restore-snapshots"
    puts "\n⚠️  Remember to restart your Rails app to pick up the restored database!"
  rescue => e
    puts "\n❌ Restore failed: #{e.message}"
    raise
  end
end
