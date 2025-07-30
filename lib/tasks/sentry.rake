# frozen_string_literal: true

namespace :sentry do
  desc "Test Sentry integration"
  task test: :environment do
    puts "Testing Sentry integration..."

    begin
      Sentry.capture_message("Test message from Rails app")
      puts "✓ Test message sent to Sentry"
    rescue => e
      puts "✗ Failed to send test message: #{e.message}"
    end

    begin
      1 / 0
    rescue ZeroDivisionError => e
      Sentry.capture_exception(e)
      puts "✓ Test exception sent to Sentry"
    end

    puts "\nSentry configuration:"
    puts "  DSN: #{Sentry.configuration.dsn ? "Configured" : "Not configured"}"
    puts "  Environment: #{Sentry.configuration.environment}"
    puts "  Enabled environments: #{Sentry.configuration.enabled_environments.join(", ")}"
    puts "\nCheck your BugSink dashboard to verify the test events were received."
  end
end
