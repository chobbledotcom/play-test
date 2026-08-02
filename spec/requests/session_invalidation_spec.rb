# typed: false

require "rails_helper"

RSpec.describe "Session Invalidation", type: :request do
  describe "deleted sessions are invalidated" do
    let(:user) { create(:user, password: "password123") }

    it "invalidates sessions when UserSession record is deleted" do
      # Log in to create a session
      post "/login", params: {
        session: {
          email: user.email,
          password: "password123"
        }
      }
      expect(response).to redirect_to(inspections_path)

      # Verify we can access a protected page
      get "/inspections"
      expect(response).to be_successful

      # Get the session token
      user_session = UserSession.last
      expect(user_session).to be_present

      # Delete the UserSession record (simulating logout from another device)
      user_session.destroy

      # Try to access a protected page again
      get "/inspections"

      # Should be redirected to login because session is invalid
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("forms.session_new.status.login_required"))
    end

    it "invalidates sessions after 30 days of inactivity" do
      post "/login", params: {
        session: {email: user.email, password: "password123"}
      }
      user_session = UserSession.last
      user_session.update_column(
        :last_active_at,
        UserSession::INACTIVITY_TIMEOUT.ago - 1.second
      )

      get "/inspections"

      expect(response).to redirect_to(login_path)
      expect(UserSession.exists?(user_session.id)).to be false
    end

    it "revokes every old session and rotates the current one after a password change" do
      post "/login", params: {
        session: {email: user.email, password: "password123"}
      }
      current_token = UserSession.last.session_token
      other_session = create(:user_session, user: user)

      patch update_password_user_path(user), params: {
        user: {
          current_password: "password123",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }

      expect(response).to redirect_to(root_path)
      expect(UserSession.where(session_token: [current_token, other_session.session_token]))
        .to be_empty
      expect(user.user_sessions.count).to eq(1)
      expect(user.user_sessions.first.session_token).not_to eq(current_token)
    end

    it "allows logout everywhere else functionality" do
      # Create multiple sessions

      # First login
      post "/login", params: {
        session: {email: user.email, password: "password123"}
      }
      session1 = UserSession.last
      session1_token = session1.session_token

      # Simulate second login from different device
      # Clear cookies to simulate new device
      reset!

      post "/login", params: {
        session: {email: user.email, password: "password123"}
      }
      session2 = UserSession.last
      session2_token = session2.session_token

      expect(user.user_sessions.count).to eq(2)

      # Use logout everywhere else
      delete "/users/#{user.id}/logout_everywhere_else"

      # Current session should still work
      get "/inspections"
      expect(response).to be_successful

      # But the other session should be deleted
      expect(UserSession.where(session_token: session1_token).exists?).to be false
      expect(UserSession.where(session_token: session2_token).exists?).to be true
    end
  end
end
