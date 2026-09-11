# typed: strict
# frozen_string_literal: true

module MagicContainer
  # Details for one S3-compatible endpoint, used for both the Active Storage
  # bucket and the Litestream replica bucket.
  class S3Details < T::Struct
    const :endpoint, String
    const :region, String
    const :access_key_id, String
    const :secret_access_key, String
    const :bucket, String
  end
end
