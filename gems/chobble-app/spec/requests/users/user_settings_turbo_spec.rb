require "rails_helper"

RSpec.describe "User Settings Turbo Updates", type: :request do
  let(:user) { create(:chobble_app_user) }

  before do
    login_as(user)
  end

  describe "PATCH /users/:id/update_settings" do
    context "with turbo stream format" do
      it "updates settings and returns turbo streams" do
        patch update_settings_user_path(user), params: {
          user: {
            phone: "123-456-7890",
            theme: "dark"
          }
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")

        # Check that save message turbo stream is present
        expect(response.body).to include('turbo-stream action="replace" target="form_save_message"')

        # Check success message
        expect(response.body).to include(I18n.t("users.messages.settings_updated"))
      end

      it "returns turbo streams with logo upload" do
        logo_file = fixture_file_upload("test_image.jpg", "image/jpeg")

        patch update_settings_user_path(user), params: {
          user: {
            logo: logo_file
          }
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")

        # Logo should be attached
        user.reload
        expect(user.logo).to be_attached

        # Response should show success message
        expect(response.body).to include('turbo-stream action="replace" target="form_save_message"')
      end

      it "returns error turbo streams on validation failure" do
        # Try to upload an invalid file
        invalid_file = fixture_file_upload("test.txt", "text/plain")

        patch update_settings_user_path(user), params: {
          user: {
            logo: invalid_file
          }
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # With invalid image, it redirects with error
        expect(response).to have_http_status(:found)
        expect(flash[:alert]).to eq(I18n.t("errors.messages.invalid_image_format"))

        # File should not be attached
        user.reload
        expect(user.logo).not_to be_attached
      end
    end
  end
end
