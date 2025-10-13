# typed: false
# frozen_string_literal: true

# Validate S3 configuration when USE_S3_STORAGE is enabled
if Rails.configuration.use_s3_storage
  Rails.application.config.after_initialize do
    required_vars = %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET]
    missing_vars = required_vars.select { |var| ENV[var].nil? }

    if missing_vars.any?
      raise "Missing required S3 configuration: #{missing_vars.join(", ")}. Please set these environment variables."
    end
  end
end
