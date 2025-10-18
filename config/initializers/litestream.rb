# typed: false
# frozen_string_literal: true

# Litestream configuration for SQLite replication to S3
# Integrated with Puma via the litestream plugin
# See config/puma.rb for plugin configuration

Rails.application.configure do
  # Configure S3 credentials for Litestream replication
  config.litestream.replica_bucket = ENV["LITESTREAM_S3_BUCKET"]
  config.litestream.replica_key_id = ENV["LITESTREAM_ACCESS_KEY_ID"]
  config.litestream.replica_access_key = ENV["LITESTREAM_SECRET_ACCESS_KEY"]

  # Optional: Custom S3 endpoint (for S3-compatible services)
  if ENV["LITESTREAM_S3_ENDPOINT"].present?
    config.litestream.replica_endpoint = ENV["LITESTREAM_S3_ENDPOINT"]
  end

  # Optional: S3 region
  if ENV["LITESTREAM_S3_REGION"].present?
    config.litestream.replica_region = ENV["LITESTREAM_S3_REGION"]
  end
end
