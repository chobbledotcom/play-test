# typed: false
# frozen_string_literal: true

return if Rails.env.test?

require "sentry-ruby"
require "sentry-rails"
require Rails.root.join("app/services/sentry_availability_service")

observability = Rails.configuration.observability
dsn = observability.sentry_dsn

# Bugsink is self-hosted and sometimes unavailable when the app boots. The
# SDK's send paths perform DNS lookups and TCP connects without a
# Ruby-level timeout, so a down Bugsink can stall the process indefinitely.
# Probe the DSN endpoint once and, when Bugsink is unreachable, start the
# SDK without a DSN so error reporting is a no-op instead of a hang. The
# process needs a restart to report errors again once Bugsink is back.
if Rails.env.production? && dsn.present? && !SentryAvailabilityService.available?(dsn)
  Rails.logger.warn(
    "Sentry (Bugsink) unreachable at boot - error reporting disabled until restart"
  )
  dsn = nil
end

Sentry.init do |config|
  config.dsn = dsn
  config.enabled_environments = %w[production]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.send_default_pii = false

  if observability.git_commit.present?
    config.release = observability.git_commit
  end
end

Sentry.configure_scope do |scope|
  scope.add_event_processor { SentryUserTaggingService.tag(it) }
end
