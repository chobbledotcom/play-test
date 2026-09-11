# typed: strict
# frozen_string_literal: true

# Tags Sentry events with the signed-in user. Registered as a Sentry event
# processor rather than a before_send hook: event processors run on the
# capturing thread, where request-scoped CurrentAttributes are populated,
# while before_send runs on Sentry's background worker thread where they
# are always empty.
class SentryUserTaggingService
  extend T::Sig

  sig { params(event: T.untyped).returns(T.untyped) }
  def self.tag(event)
    user = Current.user
    event.user = {id: user.id, email: user.email} if user
    event
  end
end
