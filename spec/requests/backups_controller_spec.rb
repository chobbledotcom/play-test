# typed: false

require "rails_helper"

RSpec.describe "Backups", type: :request do
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

  describe "GET /backups/download" do
    context "when logged in as admin" do
      before { login_as(admin_user) }

      it "rejects invalid date format" do
        get download_backups_path, params: {date: "not-a-date"}
        expect(response).to redirect_to(backups_path)
        expect(flash[:error]).to eq(I18n.t("backups.errors.invalid_date"))
      end

      it "rejects empty date parameter" do
        get download_backups_path, params: {date: ""}
        expect(response).to redirect_to(backups_path)
        expect(flash[:error]).to eq(I18n.t("backups.errors.invalid_date"))
      end

      it "rejects nil date parameter" do
        get download_backups_path, params: {}
        expect(response).to redirect_to(backups_path)
        expect(flash[:error]).to eq(I18n.t("backups.errors.invalid_date"))
      end

      context "with valid date" do
        let(:valid_date) { "2024-01-15" }
        let(:valid_key) { "db_backups/database-2024-01-15.tar.gz" }

        before do
          # Mock S3 service
          s3_service = double("S3Service")
          allow(s3_service).to receive(:class).and_return(double(name: "ActiveStorage::Service::S3Service"))
          allow(ActiveStorage::Blob).to receive(:service).and_return(s3_service)

          # Mock bucket for backup_exists? check
          bucket = double("bucket")
          allow(s3_service).to receive(:send).with(:bucket).and_return(bucket)

          backup = double("backup",
            key: valid_key,
            size: 5_242_880,
            last_modified: Time.zone.parse("2024-01-15 10:00:00"))

          allow(bucket).to receive(:objects).with(prefix: "db_backups/").and_return([backup])

          # Mock object for presigned URL generation
          s3_object = double("S3Object")
          allow(bucket).to receive(:object).with(valid_key).and_return(s3_object)
          allow(s3_object).to receive(:presigned_url).and_return("https://s3.example.com/signed-url")
        end

        it "redirects to presigned S3 URL for valid backup" do
          get download_backups_path, params: {date: valid_date}
          expect(response).to redirect_to("https://s3.example.com/signed-url")
        end
      end

      it "handles non-existent backup gracefully" do
        # Mock empty backup list
        s3_service = double("S3Service")
        allow(s3_service).to receive(:class).and_return(double(name: "ActiveStorage::Service::S3Service"))
        allow(ActiveStorage::Blob).to receive(:service).and_return(s3_service)

        bucket = double("bucket")
        allow(s3_service).to receive(:send).with(:bucket).and_return(bucket)
        allow(bucket).to receive(:objects).with(prefix: "db_backups/").and_return([])

        get download_backups_path, params: {date: "2099-12-31"}
        expect(response).to redirect_to(backups_path)
        expect(flash[:error]).to eq(I18n.t("backups.errors.backup_not_found"))
      end
    end

    context "when logged in as regular user" do
      before { login_as(regular_user) }

      it "redirects to root with unauthorized message" do
        get download_backups_path, params: {date: "2024-01-15"}
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("forms.session_new.status.admin_required"))
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get download_backups_path, params: {date: "2024-01-15"}
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
