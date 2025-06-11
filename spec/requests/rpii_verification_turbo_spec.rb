require "rails_helper"

RSpec.describe "RPII Verification Turbo Streams", type: :request do
  let(:admin_user) { create(:user, email: "admin@example.com", name: "Admin User") }
  let(:user) { create(:user, name: "John Smith", rpii_inspector_number: "12345") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    login_as(admin_user)
  end

  describe "POST /users/:id/verify_rpii" do
    context "with Turbo Stream request" do
      it "returns a turbo stream response for successful verification" do
        allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
          valid: true,
          inspector: {
            name: "John Smith",
            number: "12345",
            qualifications: "RPII Inspector"
          }
        })

        post verify_rpii_user_path(user), headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream action="replace" target="rpii_verification_result"')
        expect(response.body).to include(I18n.t("users.verification.success_header"))
        expect(response.body).to include("John Smith")
        expect(response.body).to include("12345")
        expect(response.body).to include("RPII Inspector")
      end

      it "returns a turbo stream response for name mismatch" do
        allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
          valid: true,
          inspector: {
            name: "Jane Doe",
            number: "12345",
            qualifications: "RPII Inspector"
          }
        })

        post verify_rpii_user_path(user), headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('turbo-stream action="replace" target="rpii_verification_result"')
        expect(response.body).to include(I18n.t("users.verification.failure_header"))
        # Check for the message with HTML entities
        expect(response.body).to include("Name mismatch: User name")
        expect(response.body).to include("John Smith")
        expect(response.body).to include("Jane Doe")
      end
    end

    context "with regular HTML request" do
      it "redirects with flash message for successful verification" do
        allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
          valid: true,
          inspector: {
            name: "John Smith",
            number: "12345",
            qualifications: "RPII Inspector"
          }
        })

        post verify_rpii_user_path(user)

        expect(response).to redirect_to(edit_user_path(user))
        expect(flash[:notice]).to eq(I18n.t("users.messages.rpii_verified"))
      end

      it "redirects with error message for failed verification" do
        allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
          valid: false,
          inspector: nil
        })

        post verify_rpii_user_path(user)

        expect(response).to redirect_to(edit_user_path(user))
        expect(flash[:alert]).to eq(I18n.t("users.messages.rpii_not_found"))
      end
    end
  end
end
