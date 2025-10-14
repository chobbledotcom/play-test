# typed: strict
# frozen_string_literal: true

class ObservabilityConfig < T::Struct
  extend T::Sig

  const :ntfy_channel_developer, T.nilable(String)
  const :ntfy_channel_admin, T.nilable(String)
  const :sentry_dsn, T.nilable(String)
  const :git_commit, T.nilable(String)

  sig do
    params(env: T::Hash[String, T.nilable(String)])
      .returns(ObservabilityConfig)
  end
  def self.from_env(env)
    new(
      ntfy_channel_developer: env["NTFY_CHANNEL_DEVELOPER"],
      ntfy_channel_admin: env["NTFY_CHANNEL_ADMIN"],
      sentry_dsn: env["SENTRY_DSN"],
      git_commit: env["RENDER_GIT_COMMIT"]
    )
  end
end
