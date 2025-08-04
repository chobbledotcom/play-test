# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  require "prosopite"

  Rails.application.config.after_initialize do
    # Configure Prosopite to send N+1 warnings to Sentry
    if defined?(Sentry)
      Prosopite.custom_logger = lambda do |message|
        # Log to Rails logger
        Rails.logger.warn(message)

        # Send to Sentry
        Sentry.capture_message(
          "N+1 Query Detected: #{message}",
          level: :warning,
          extra: {
            prosopite_message: message,
            backtrace: caller(5, 10) # Skip Prosopite's internal calls
          }
        )
      end
    else
      # Fallback to Rails logger only
      Prosopite.custom_logger = Rails.logger
    end

    # Ignore certain patterns that are not true N+1s
    Prosopite.allow_stack_paths = [
      "active_storage",
      "active_record/associations/preloader"
    ]

    # Log in development, but don't raise in tests to avoid breaking existing tests
    # Prosopite will still detect N+1s and log them
    # Prosopite.raise = Rails.env.test?
  end
end