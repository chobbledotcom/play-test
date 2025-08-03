# frozen_string_literal: true

namespace :debug do
  desc "Debug cron environment and paths"
  task cron: :environment do
    puts "=== DEBUG CRON ENVIRONMENT ==="
    puts "Time: #{Time.current}"
    puts "Rails.env: #{Rails.env}"
    puts "Rails.root: #{Rails.root}"
    puts "Working directory: #{Dir.pwd}"
    puts "Database config: #{Rails.configuration.database_configuration[Rails.env].inspect}"
    
    db_path = Rails.configuration.database_configuration[Rails.env]["database"]
    full_db_path = db_path.start_with?("/") ? db_path : Rails.root.join(db_path)
    
    puts "Database path (from config): #{db_path}"
    puts "Full database path: #{full_db_path}"
    puts "Database exists?: #{File.exist?(full_db_path)}"
    puts "Storage directory contents:"
    
    storage_dir = Rails.root.join("storage")
    if Dir.exist?(storage_dir)
      Dir.entries(storage_dir).each do |entry|
        next if entry.start_with?(".")
        puts "  - #{entry}"
      end
    else
      puts "  Storage directory not found!"
    end
    
    puts "\nEnvironment variables:"
    %w[USE_S3_STORAGE S3_ENDPOINT S3_BUCKET RAILS_ENV PATH].each do |var|
      puts "  #{var}: #{ENV[var]}"
    end
    
    puts "\nSQLite3 available?: #{system('which sqlite3 > /dev/null 2>&1')}"
    puts "=== END DEBUG ==="
  end
end