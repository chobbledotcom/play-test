# frozen_string_literal: true

return if Rails.env.test?

require "sentry-ruby"
require "sentry-rails"

Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.send_default_pii = false

  config.before_send = lambda do |event, hint|
    if hint[:exception]
      exception = hint[:exception]

      if exception.is_a?(ActionController::InvalidAuthenticityToken)
        csrf_ignored_actions = [
          ["sessions", "create"],
          ["users", "create"]
        ]

        if event.contexts && event.contexts[:rack_env]
          env = event.contexts[:rack_env]
          if env["action_controller.instance"]
            controller = env["action_controller.instance"]
            controller_name = controller.controller_name
            action_name = controller.action_name

            action = [controller_name, action_name]
            return nil if csrf_ignored_actions.include?(action)
          end
        end
      end
    end

    if defined?(Current) && Current.user
      event.user = {
        id: Current.user.id,
        email: Current.user.email
      }
    end

    event
  end

  config.release = ENV["RENDER_GIT_COMMIT"] if ENV["RENDER_GIT_COMMIT"].present?
end
