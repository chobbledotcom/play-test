# frozen_string_literal: true

module S3Helpers
  extend ActiveSupport::Concern

  private

  def ensure_s3_enabled
    return if ENV["USE_S3_STORAGE"] == "true"

    error_msg = "S3 storage is not enabled. Set USE_S3_STORAGE=true in your .env file"
    raise error_msg
  end

  def validate_s3_config
    required_vars = %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET]
    missing_vars = required_vars.select { |var| ENV[var].blank? }

    if missing_vars.any?
      error_msg = "Missing required S3 environment variables: #{missing_vars.join(", ")}"

      Sentry.capture_message(error_msg, level: "error", extra: {
        missing_vars: missing_vars,
        context: self.class.name,
        environment: Rails.env
      })

      raise error_msg
    end
  end

  def get_s3_service
    service = ActiveStorage::Blob.service

    unless service.is_a?(ActiveStorage::Service::S3Service)
      error_msg = "Active Storage is not configured to use S3. Current service: #{service.class.name}"
      raise error_msg
    end

    service
  end

  def handle_s3_errors
    yield
  rescue Aws::S3::Errors::ServiceError => e
    Sentry.capture_exception(e)
    raise
  rescue => e
    Sentry.capture_exception(e)
    raise
  end
end