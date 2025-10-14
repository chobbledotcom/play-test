# typed: strict
# frozen_string_literal: true

class S3Config < T::Struct
  extend T::Sig

  const :enabled, T::Boolean
  const :endpoint, T.nilable(String)
  const :bucket, T.nilable(String)
  const :region, T.nilable(String)

  sig { params(env: T::Hash[String, T.nilable(String)]).returns(S3Config) }
  def self.from_env(env)
    new(
      enabled: env["USE_S3_STORAGE"] == "true",
      endpoint: env["S3_ENDPOINT"],
      bucket: env["S3_BUCKET"],
      region: env["S3_REGION"]
    )
  end
end
