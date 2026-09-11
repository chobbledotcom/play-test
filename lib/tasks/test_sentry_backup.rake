# typed: false
# frozen_string_literal: true

namespace :test do
  desc "Test Sentry error reporting in backup task"
  task test_backup_error: :environment do
    # Test 1: Force an error in database path
    puts "Test 1: Testing with invalid database configuration..."

    # Temporarily override the database path
    original_config = Rails.configuration.database_configuration[Rails.env]["database"]
    Rails.configuration.database_configuration[Rails.env]["database"] = "/nonexistent/path/database.sqlite3"

    begin
      Rake::Task["backup:create"].invoke
    rescue => e
      puts "Caught error: #{e.class} - #{e.message}"
      Sentry.capture_exception(e)
    ensure
      # Restore original config
      Rails.configuration.database_configuration[Rails.env]["database"] = original_config
    end

    puts
    puts "Test 2: Testing with nil database path..."

    # Test with nil database path
    Rails.configuration.database_configuration[Rails.env]["database"] = nil

    begin
      Rake::Task["backup:create"].reenable
      Rake::Task["backup:create"].invoke
    rescue SystemExit => e
      puts "Task exited with status: #{e.status}"
    rescue => e
      puts "Caught error: #{e.class} - #{e.message}"
      Sentry.capture_exception(e)
    ensure
      Rails.configuration.database_configuration[Rails.env]["database"] = original_config
    end

    puts
    puts "✅ Tests complete! Check Sentry for:"
    puts "  - Database file not found errors"
    puts "  - Any unexpected exceptions"
  end
end
