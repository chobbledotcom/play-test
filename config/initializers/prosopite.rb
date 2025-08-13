# typed: false
# frozen_string_literal: true

# Only load Prosopite in development/test environments
if Rails.env.local?
  require "prosopite"

  Rails.application.config.active_record.query_log_tags_enabled = true

  Rails.application.config.after_initialize do
    Prosopite.rails_logger = Rails.logger
    Prosopite.prosopite_logger = true
    Prosopite.raise = true if Rails.env.development?

    Prosopite.allow_stack_paths = %w[
      mission_control
      solid_queue
    ]

    Prosopite.custom_logger = if defined?(Sentry)
      logger = Object.new
      logger.define_singleton_method(:warn) do |message|
        Rails.logger.warn(message)
        sentry_message = I18n.t("prosopite.n_plus_one_detected",
          message: message)
        Sentry.capture_message(
          sentry_message,
          level: :warning,
          extra: {
            prosopite_message: message,
            backtrace: caller(5, 10)
          }
        )
      end
      logger
    else
      Rails.logger
    end
  end
end
