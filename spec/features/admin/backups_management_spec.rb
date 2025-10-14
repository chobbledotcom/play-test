# typed: false

require "rails_helper"

RSpec.feature "Backups Management", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }

  define_method(:set_s3_enabled) do
    config = S3Config.new(
      use_s3_storage: true,
      s3_endpoint: "https://s3.example.com",
      s3_bucket: "test-bucket",
      s3_region: "us-east-1"
    )
    Rails.configuration.s3 = config
  end

  define_method(:set_s3_disabled) do
    config = S3Config.new(
      use_s3_storage: false,
      s3_endpoint: nil,
      s3_bucket: nil,
      s3_region: nil
    )
    Rails.configuration.s3 = config
  end

  before do
    set_s3_enabled
  end

  after do
    set_s3_disabled
  end

  scenario "admin can access backups page" do
    # Mock S3 service and bucket
    s3_service = double("S3Service")
    allow(s3_service).to receive(:class).and_return(double(name: "ActiveStorage::Service::S3Service"))
    allow(ActiveStorage::Blob).to receive(:service).and_return(s3_service)

    bucket = double("bucket")
    allow(s3_service).to receive(:send).with(:bucket).and_return(bucket)

    # Mock S3 objects
    backup1 = double("backup1",
      key: "db_backups/database-2024-01-15.tar.gz",
      size: 5_242_880, # 5MB
      last_modified: Time.zone.parse("2024-01-15 10:00:00"))

    backup2 = double("backup2",
      key: "db_backups/database-2024-01-14.tar.gz",
      size: 4_194_304, # 4MB
      last_modified: Time.zone.parse("2024-01-14 10:00:00"))

    allow(bucket).to receive(:objects).with(prefix: "db_backups/").and_return([backup1, backup2])

    sign_in(admin_user)
    visit admin_path

    click_link I18n.t("navigation.backups")

    expect(page).to have_content(I18n.t("backups.title"))
    expect(page).to have_content("database-2024-01-15.tar.gz")
    expect(page).to have_content("5.0 MB")
    expect(page).to have_content("database-2024-01-14.tar.gz")
    expect(page).to have_content("4.0 MB")
    expect(page).to have_link("database-2024-01-15.tar.gz")
    expect(page).to have_link("database-2024-01-14.tar.gz")
  end

  scenario "regular user cannot access backups page" do
    sign_in(regular_user)
    visit backups_path

    expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
    expect(current_path).to eq(root_path)
  end

  scenario "shows error when S3 fetch fails" do
    s3_service = double("S3Service")
    allow(s3_service).to receive(:class).and_return(double(name: "ActiveStorage::Service::S3Service"))
    allow(ActiveStorage::Blob).to receive(:service).and_return(s3_service)
    allow(s3_service).to receive(:send).and_raise("S3 Error")

    sign_in(admin_user)

    expect { visit backups_path }.to raise_error("S3 Error")
  end

  scenario "redirects if S3 not enabled" do
    set_s3_disabled

    sign_in(admin_user)
    visit backups_path

    expect(page).to have_content(I18n.t("backups.errors.s3_not_enabled"))
    expect(current_path).to eq(admin_path)

    set_s3_enabled
  end
end
