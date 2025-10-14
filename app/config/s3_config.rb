# typed: strict
# frozen_string_literal: true

class S3Config < T::Struct
  extend T::Sig

  const :use_s3_storage, T::Boolean
  const :s3_endpoint, T.nilable(String)
  const :s3_bucket, T.nilable(String)
  const :s3_region, T.nilable(String)

  sig { params(env: T::Hash[String, T.nilable(String)]).returns(S3Config) }
  def self.from_env(env)
    new(
      use_s3_storage: env["USE_S3_STORAGE"] == "true",
      s3_endpoint: env["S3_ENDPOINT"],
      s3_bucket: env["S3_BUCKET"],
      s3_region: env["S3_REGION"]
    )
  end
end
