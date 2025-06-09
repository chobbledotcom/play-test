namespace :storage do
  desc "Cleanup unattached ActiveStorage blobs older than 2 days"
  task cleanup: :environment do
    ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago).find_each(&:purge_later)
    puts "Scheduled cleanup of unattached blobs older than 2 days"
  end
end
