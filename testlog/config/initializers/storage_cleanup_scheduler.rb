Rails.application.config.after_initialize do
  # Skip in test environment
  unless Rails.env.test?
    # Schedule the first run for 2:00 AM
    run_at = Time.now.midnight + 2.hours
    run_at += 1.day if run_at < Time.now

    # Set next run time for display in the UI
    StorageCleanupJob.next_run_at = run_at

    # Schedule the job
    StorageCleanupJob.set(wait_until: run_at).perform_later

    Rails.logger.info "Scheduled initial StorageCleanupJob for #{run_at}"
  end
end
