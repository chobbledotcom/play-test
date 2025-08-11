require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "POST /login" do
    let(:user) { create(:user, password: "password123") }

    context "with valid credentials" do
      it "logs in the user and creates a user session" do
        expect {
          post "/login", params: {
            session: {
              email: user.email,
              password: "password123"
            }
          }
        }.to change { UserSession.count }.by(1)

        expect(response).to redirect_to(inspections_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("session.login.success"))

        # Check that UserSession was created correctly
        user_session = UserSession.last
        expect(user_session.user_id).to eq(user.id)
        expect(user_session.ip_address).to be_present
        # user_agent might be nil in test environment
        expect(user_session.session_token).to be_present
        expect(user_session.last_active_at).to be_present
      end
    end

    context "with invalid credentials" do
      it "does not log in the user and shows error" do
        expect {
          post "/login", params: {
            session: {
              email: user.email,
              password: "wrongpassword"
            }
          }
        }.not_to change { UserSession.count }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("session.login.error"))
      end
    end
  end

  describe "DELETE /logout" do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    it "logs out the user and deletes the user session" do
      # Ensure a session exists
      expect(UserSession.count).to eq(1)

      delete "/logout"

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("session.logout.success"))

      # Session should be deleted
      expect(UserSession.count).to eq(0)
    end
  end
end
