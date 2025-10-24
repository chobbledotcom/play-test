# typed: false
# frozen_string_literal: true

return if Rails.env.test?

require "sentry-ruby"
require "sentry-rails"

Sentry.init do |config|
  observability = Rails.configuration.observability

  config.dsn = observability.sentry_dsn
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.send_default_pii = false

  config.before_send = lambda do |event, hint|
    if Current.user
      event.user = {
        id: Current.user.id,
        email: Current.user.email
      }
    end

    event
  end

  if observability.git_commit.present?
    config.release = observability.git_commit
  end
end
