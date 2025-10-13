# typed: false
# frozen_string_literal: true

return if Rails.env.test?

require "sentry-ruby"
require "sentry-rails"

Sentry.init do |config|
  # Store RENDER_GIT_COMMIT before ENV protection kicks in
  render_git_commit = ENV["RENDER_GIT_COMMIT"]

  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.send_default_pii = false

  config.before_send = lambda do |event, hint|
    if defined?(Current) && Current.user
      event.user = {
        id: Current.user.id,
        email: Current.user.email
      }
    end

    event
  end

  config.release = render_git_commit if render_git_commit.present?
end
