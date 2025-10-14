# typed: strict
# frozen_string_literal: true

# Typed configuration for user/authentication settings
class UsersConfig < T::Struct
  extend T::Sig

  # Whether to use simple activation (no email confirmation)
  const :simple_activation, T::Boolean

  # Pattern for emails that should be automatically marked as admin
  const :admin_emails_pattern, T.nilable(String)

  sig { params(env: T::Hash[String, T.nilable(String)]).returns(UsersConfig) }
  def self.from_env(env)
    new(
      simple_activation: env["SIMPLE_USER_ACTIVATION"] == "true",
      admin_emails_pattern: env["ADMIN_EMAILS_PATTERN"]
    )
  end
end
