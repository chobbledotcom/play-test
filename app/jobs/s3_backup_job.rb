# typed: false
# frozen_string_literal: true

class S3BackupJob < ApplicationJob
  queue_as :default

  def perform
    # Ensure Rails is fully loaded for background jobs
    Rails.application.eager_load! if Rails.env.production?

    result = S3BackupService.new.perform

    Rails.logger.info "S3BackupJob completed successfully"
    Rails.logger.info "Backup location: #{result[:location]}"
    Rails.logger.info "Backup size: #{result[:size_mb]} MB"
    Rails.logger.info "Deleted #{result[:deleted_count]} old backups" if result[:deleted_count].positive?
  end
end
