# typed: false
# frozen_string_literal: true

class BackupJob < ApplicationJob
  queue_as :default

  def perform(destination = "both")
    # Ensure Rails is fully loaded for background jobs
    Rails.application.eager_load! if Rails.env.production?

    BackupService.new.perform(destination:)

    Rails.logger.info "BackupJob completed successfully"
  end
end
