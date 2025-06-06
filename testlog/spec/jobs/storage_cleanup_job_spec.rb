require "rails_helper"

describe StorageCleanupJob do
  it "purges unattached blobs older than 2 days" do
    # Create test data using fixtures
    file_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
    file_data = File.read(file_path)
    checksum = Digest::MD5.base64digest(file_data)

    # Create an unattached blob that's older than 2 days
    old_blob = ActiveStorage::Blob.create!(
      key: SecureRandom.uuid,
      filename: "old_test.jpg",
      content_type: "image/jpeg",
      metadata: {},
      service_name: "test",
      byte_size: file_data.bytesize,
      checksum: checksum
    )
    old_blob.update_column(:created_at, 3.days.ago)

    # Create a recent unattached blob (less than 2 days old)
    recent_blob = ActiveStorage::Blob.create!(
      key: SecureRandom.uuid,
      filename: "recent_test.jpg",
      content_type: "image/jpeg",
      metadata: {},
      service_name: "test",
      byte_size: file_data.bytesize,
      checksum: checksum
    )
    recent_blob.update_column(:created_at, 1.day.ago)

    # Create a user (we no longer test with image attachments)
    user = User.create!(email: "test@example.com", password: "password123", admin: false)
    user.inspections.create!(
      inspector: "Test Inspector",
      serial: "SN12345",
      location: "Test Location"
    )

    # Verify the initial state
    old_blob_query = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago)
    expect(old_blob_query.count).to eq(1)
    expect(old_blob_query.first.id).to eq(old_blob.id)

    # Expect purge_later to be called on the old blob only
    expect_any_instance_of(ActiveStorage::Blob).to receive(:purge_later).once

    # Perform the job
    StorageCleanupJob.new.perform
  end

  it "schedules itself to run again in production" do
    job = StorageCleanupJob.new

    # Mock Rails.env to return production
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

    # Need to mock both the count and find_each chains to avoid actual database calls
    blob_query = double
    allow(blob_query).to receive(:count).and_return(0)
    allow(blob_query).to receive(:find_each)
    allow(ActiveStorage::Blob).to receive(:unattached).and_return(ActiveStorage::Blob)
    allow(ActiveStorage::Blob).to receive(:where).and_return(blob_query)

    # Expect the job to schedule itself to run tomorrow
    expect(StorageCleanupJob).to receive(:set).with(wait: 1.day).and_return(StorageCleanupJob)
    expect(StorageCleanupJob).to receive(:perform_later)

    # Run the job
    job.perform
  end

  # We no longer test attached blobs as the app no longer uses images

  # We no longer test detached blobs as the app no longer uses images

  it "correctly handles multiple unattached blobs for purging" do
    file_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
    file_data = File.read(file_path)
    checksum = Digest::MD5.base64digest(file_data)

    # Create several unattached blobs of different ages
    old_blobs = []

    # Create 3 old unattached blobs (older than 2 days)
    3.times do |i|
      blob = ActiveStorage::Blob.create!(
        key: SecureRandom.uuid,
        filename: "old_unattached_#{i}.jpg",
        content_type: "image/jpeg",
        metadata: {},
        service_name: "test",
        byte_size: file_data.bytesize,
        checksum: checksum
      )
      blob.update_column(:created_at, (3 + i).days.ago) # 3, 4, and 5 days old
      old_blobs << blob
    end

    # Create 2 recent unattached blobs (less than 2 days old)
    recent_blobs = []
    2.times do |i|
      blob = ActiveStorage::Blob.create!(
        key: SecureRandom.uuid,
        filename: "recent_unattached_#{i}.jpg",
        content_type: "image/jpeg",
        metadata: {},
        service_name: "test",
        byte_size: file_data.bytesize,
        checksum: checksum
      )
      blob.update_column(:created_at, (i + 1).hours.ago)
      recent_blobs << blob
    end

    # Verify initial state
    expect(ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago).count).to eq(3)

    # Mock the query parts to control the flow and avoid actual purge_later calls
    blob_query = double
    allow(blob_query).to receive(:count).and_return(3)
    allow(blob_query).to receive(:find_each).and_yield(old_blobs[0]).and_yield(old_blobs[1]).and_yield(old_blobs[2])
    allow(ActiveStorage::Blob).to receive(:unattached).and_return(ActiveStorage::Blob)
    allow(ActiveStorage::Blob).to receive(:where).and_return(blob_query)

    # Expect purge_later to be called on each old blob
    old_blobs.each do |blob|
      expect(blob).to receive(:purge_later).once
    end

    # Run the job
    job = StorageCleanupJob.new
    allow(job).to receive(:schedule_next_run) # Prevent scheduling next run
    job.perform
  end
end
