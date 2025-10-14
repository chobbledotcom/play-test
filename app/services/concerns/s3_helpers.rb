# frozen_string_literal: true

module S3Helpers
  extend ActiveSupport::Concern

  private

  def ensure_s3_enabled
    raise "S3 storage is not enabled" unless Rails.configuration.s3.use_s3_storage
  end

  def validate_s3_config
    required_vars = %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET]
    missing_vars = required_vars.select { |var| ENV[var].blank? }

    raise "Missing S3 config: #{missing_vars.join(", ")}" if missing_vars.any?
  end

  def get_s3_service = ActiveStorage::Blob.service
end
