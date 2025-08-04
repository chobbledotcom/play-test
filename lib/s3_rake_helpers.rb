# frozen_string_literal: true

require_relative "../app/services/concerns/s3_backup_operations"

# Helper methods for S3 operations in rake tasks
# These wrap the S3Helpers module methods to work in rake context
module S3RakeHelpers
  include S3BackupOperations

  def ensure_s3_enabled
    return if ENV["USE_S3_STORAGE"] == "true"

    error_msg = "S3 storage is not enabled. Set USE_S3_STORAGE=true in your .env file"
    Rails.logger.debug "❌ #{error_msg}"
    raise StandardError, error_msg
  end

  def validate_s3_config
    required_vars = %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET]
    missing_vars = required_vars.select { |var| ENV[var].blank? }

    if missing_vars.any?
      error_msg = "Missing required S3 environment variables: #{missing_vars.join(", ")}"
      Rails.logger.debug { "❌ #{error_msg}" }

      Sentry.capture_message(error_msg, level: "error", extra: {
        missing_vars: missing_vars,
        task: caller_locations(1, 1)[0].label,
        environment: Rails.env
      })

      raise StandardError, error_msg
    end
  end

  def get_s3_service
    service = ActiveStorage::Blob.service

    unless service.is_a?(ActiveStorage::Service::S3Service)
      error_msg = "Active Storage is not configured to use S3. Current service: #{service.class.name}"
      Rails.logger.debug { "❌ #{error_msg}" }
      raise StandardError, error_msg
    end

    service
  end

  def handle_s3_errors
    yield
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.debug { "\n❌ S3 Error: #{e.message}" }
    Sentry.capture_exception(e)
    raise
  rescue => e
    Rails.logger.debug { "\n❌ Unexpected error: #{e.message}" }
    Sentry.capture_exception(e)
    raise
  end
end
