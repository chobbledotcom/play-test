# frozen_string_literal: true

class SentryTestService
  def perform
    results = []
    
    # Test 1: Send a test message
    begin
      Sentry.capture_message("Test message from Rails app")
      results << { test: "message", status: "success", message: "Test message sent to Sentry" }
    rescue => e
      results << { test: "message", status: "failed", message: "Failed to send test message: #{e.message}" }
    end

    # Test 2: Send a test exception
    begin
      1 / 0
    rescue ZeroDivisionError => e
      Sentry.capture_exception(e)
      results << { test: "exception", status: "success", message: "Test exception sent to Sentry" }
    end

    # Test 3: Send exception with extra context
    begin
      Sentry.with_scope do |scope|
        scope.set_context("test_info", {
          source: "SentryTestService",
          timestamp: Time.current.iso8601,
          rails_env: Rails.env
        })
        scope.set_tags(test_type: "integration_test")
        
        raise "This is a test error with context"
      end
    rescue => e
      Sentry.capture_exception(e)
      results << { test: "exception_with_context", status: "success", message: "Test exception with context sent to Sentry" }
    end

    # Return results and configuration info
    {
      results: results,
      configuration: {
        dsn_configured: Sentry.configuration.dsn.present?,
        environment: Sentry.configuration.environment,
        enabled_environments: Sentry.configuration.enabled_environments
      }
    }
  end

  def test_error_type(error_type)
    case error_type
    when :database_not_found
      # Simulate database not found error
      Sentry.capture_message("Test: Database file not found", level: "error", extra: {
        database_path: "/nonexistent/database.sqlite3",
        test_type: "simulated_error"
      })
    when :missing_config
      # Simulate missing configuration error
      Sentry.capture_message("Test: Missing S3 configuration", level: "error", extra: {
        missing_vars: ["S3_ENDPOINT", "S3_BUCKET"],
        test_type: "simulated_error"
      })
    when :generic_exception
      # Raise and capture a generic exception
      begin
        raise StandardError, "This is a test exception from SentryTestService"
      rescue => e
        Sentry.capture_exception(e, extra: {
          test_type: "generic_exception",
          source: "SentryTestService#test_error_type"
        })
      end
    else
      raise ArgumentError, "Unknown error type: #{error_type}"
    end
  end
end