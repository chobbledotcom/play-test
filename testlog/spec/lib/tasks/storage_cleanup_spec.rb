require "rails_helper"
require "rake"

describe "storage:cleanup rake task" do
  before do
    Rake.application.rake_require "tasks/storage_cleanup"
    Rake::Task.define_task(:environment)
  end

  it "schedules purging of unattached blobs older than 2 days" do
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

    # Backdate it
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

    # Create a user without attaching an image, since we removed image functionality
    user = User.create!(email: "test@example.com", password: "password123", admin: false)
    user.inspections.create!(
      inspector: "Test Inspector",
      serial: "SN12345",
      location: "Test Location"
    )

    # Mock the purge_later method to prevent actual purging
    old_blob_query = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago)

    # Verify the initial state
    expect(old_blob_query.count).to eq(1)
    expect(old_blob_query.first.id).to eq(old_blob.id)

    # Expect purge_later to be called on the old blob
    expect_any_instance_of(ActiveStorage::Blob).to receive(:purge_later).once

    # Run the task
    Rake::Task["storage:cleanup"].invoke
  end
end
