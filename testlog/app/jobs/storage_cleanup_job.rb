class StorageCleanupJob < ApplicationJob
  queue_as :default

  # Class variable to track last execution and next scheduled time
  cattr_accessor :last_run_at, :next_run_at

  def perform
    # Find unattached blobs older than 2 days and schedule them for deletion
    count = ActiveStorage::Blob.unattached
      .where("active_storage_blobs.created_at <= ?", 2.days.ago)
      .count

    # Only log if we found something to clean up
    if count > 0
      Rails.logger.info "StorageCleanupJob: Found #{count} unattached blobs to clean up"
    end

    # Process in batches to avoid memory issues
    ActiveStorage::Blob.unattached
      .where("active_storage_blobs.created_at <= ?", 2.days.ago)
      .find_each(&:purge_later)

    # Update last run time
    self.class.last_run_at = Time.current

    # Schedule next run - this makes it easier to test
    schedule_next_run
  end

  # Re-schedule itself to run daily
  def schedule_next_run
    if Rails.env.production? || Rails.env.development?
      next_time = 1.day.from_now
      self.class.next_run_at = next_time
      self.class.set(wait: 1.day).perform_later
    end
  end

  # Check if a job is scheduled
  def self.scheduled?
    next_run_at.present?
  end
end
