# typed: false
# frozen_string_literal: true

# Litestream configuration for SQLite replication to S3
# Only enabled in production when LITESTREAM_ENABLED is set to true

if Rails.env.production? && ENV["LITESTREAM_ENABLED"] == "true"
  Rails.application.configure do
    config.litestream.replica_path = Rails.root.join("config/litestream.yml")
  end
end
