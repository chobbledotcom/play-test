# frozen_string_literal: true

if Rails.env.development?
  require "prosopite"

  Rails.application.config.after_initialize do
    Prosopite.rails_logger = Rails.logger
    Prosopite.prosopite_logger = true

    Prosopite.allow_stack_paths = [
      "active_storage",
      "active_record/associations/preloader",
      "mission_control",
      "solid_queue"
    ]

    Prosopite.custom_logger = if defined?(Sentry)
      lambda do |message|
        Rails.logger.warn(message)
        Sentry.capture_message(
          "N+1 Query Detected: #{message}",
          level: :warning,
          extra: {
            prosopite_message: message,
            backtrace: caller(5, 10)
          }
        )
      end
    else
      Rails.logger
    end
  end
end
