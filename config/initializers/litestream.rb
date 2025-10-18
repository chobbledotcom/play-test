# typed: false
# frozen_string_literal: true

# Litestream configuration for SQLite replication to S3
# Integrated with Puma via the litestream plugin
# See config/puma.rb for plugin configuration
#
# Our typed config is available at Rails.configuration.litestream_config
# This initializer configures the litestream gem itself

return unless Rails.configuration.litestream_config.enabled

Rails.application.configure do
  # Configure the litestream gem with S3 credentials from our typed config
  our_config = Rails.configuration.litestream_config

  config.litestream.replica_bucket = our_config.s3_bucket
  config.litestream.replica_key_id = our_config.access_key_id
  config.litestream.replica_access_key = our_config.secret_access_key

  # Optional: Custom S3 endpoint (for S3-compatible services)
  if our_config.s3_endpoint.present?
    config.litestream.replica_endpoint = our_config.s3_endpoint
  end

  # Optional: S3 region
  if our_config.s3_region.present?
    config.litestream.replica_region = our_config.s3_region
  end
end
