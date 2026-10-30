# typed: strict
# frozen_string_literal: true

require "uri"

# Bugsink is self-hosted, so when it is down the app must not wait on it.
# Sentry's send paths (background worker sends and the at_exit flush) rely
# on DNS resolution and TCP connects that have no Ruby-level timeout, so
# an unreachable Bugsink can stall the process until it comes back. This
# probe bounds that risk with a hard cap: it runs on its own thread so an
# unresolved or unroutable DSN host cannot block boot or shutdown.
class SentryAvailabilityService
  extend T::Sig

  PROBE_TIMEOUT_SECONDS = T.let(2, Integer)

  sig { params(dsn: String).returns(T::Boolean) }
  def self.available?(dsn)
    uri = URI.parse(dsn)
    host = T.cast(uri.host, String)
    port = T.cast(uri.port, Integer)

    probe = Thread.new do
      Socket.tcp(host, port, connect_timeout: PROBE_TIMEOUT_SECONDS).close
      true
    rescue SystemCallError, SocketError, IOError
      false
    end

    # A timed-out probe thread is abandoned; it ends by itself once the
    # OS resolver or connect gives up.
    probe.join(PROBE_TIMEOUT_SECONDS) ? probe.value : false
  end
end
