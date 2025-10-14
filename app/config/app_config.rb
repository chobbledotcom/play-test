# typed: strict
# frozen_string_literal: true

class AppConfig < T::Struct
  extend T::Sig

  const :has_assessments, T::Boolean
  const :base_url, String
  const :name, String

  sig do
    params(env: T::Hash[String, T.nilable(String)])
      .returns(AppConfig)
  end
  def self.from_env(env)
    new(
      has_assessments: env["HAS_ASSESSMENTS"] == "true",
      base_url: env.fetch("BASE_URL", "http://localhost:3000"),
      name: env.fetch("APP_NAME", "Play-Test")
    )
  end
end
