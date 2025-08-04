# frozen_string_literal: true

namespace :sentry do
  desc "Test Sentry integration (immediate execution)"
  task test: :environment do
    puts "Testing Sentry integration..."

    result = SentryTestService.new.perform

    result[:results].each do |test_result|
      status_symbol = (test_result[:status] == "success") ? "✓" : "✗"
      puts "#{status_symbol} #{test_result[:message]}"
    end

    puts "\nSentry configuration:"
    puts "  DSN: #{result[:configuration][:dsn_configured] ? "Configured" : "Not configured"}"
    puts "  Environment: #{result[:configuration][:environment]}"
    puts "  Enabled environments: #{result[:configuration][:enabled_environments].join(", ")}"
    puts "\nCheck your BugSink dashboard to verify the test events were received."
  end

  desc "Test Sentry integration (via job queue)"
  task test_job: :environment do
    puts "Enqueuing Sentry test job..."
    SentryTestJob.perform_later
    puts "✅ Sentry test job enqueued successfully!"
  end

  desc "Test specific error type (via job queue)"
  task :test_error, [:type] => :environment do |_task, args|
    error_types = %i[database_not_found missing_config generic_exception]

    if args[:type].nil? || !error_types.include?(args[:type].to_sym)
      puts "❌ Please provide an error type: #{error_types.join(", ")}"
      puts "   Example: rake sentry:test_error[database_not_found]"
      exit 1
    end

    puts "Enqueuing Sentry test job with error type: #{args[:type]}..."
    SentryTestJob.perform_later(args[:type])
    puts "✅ Sentry test job enqueued successfully!"
  end
end
