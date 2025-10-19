# typed: strict
# frozen_string_literal: true

class LitestreamConfig < T::Struct
  extend T::Sig

  const :enabled, T::Boolean
  const :s3_bucket, T.nilable(String)
  const :s3_endpoint, T.nilable(String)
  const :s3_region, T.nilable(String)
  const :access_key_id, T.nilable(String)
  const :secret_access_key, T.nilable(String)

  sig do
    params(env: T::Hash[String, T.nilable(String)])
      .returns(LitestreamConfig)
  end
  def self.from_env(env)
    new(
      enabled: env["LITESTREAM_ENABLED"] == "true",
      s3_bucket: env["LITESTREAM_S3_BUCKET"],
      s3_endpoint: env["LITESTREAM_S3_ENDPOINT"],
      s3_region: env["LITESTREAM_S3_REGION"],
      access_key_id: env["LITESTREAM_ACCESS_KEY_ID"],
      secret_access_key: env["LITESTREAM_SECRET_ACCESS_KEY"]
    )
  end
end
