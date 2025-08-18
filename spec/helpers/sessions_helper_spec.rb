# typed: false

require "rails_helper"

RSpec.describe SessionsHelper, type: :helper do
  let(:user) { create(:user) }
  let(:user_session) { create(:user_session, user: user) }

  describe "#remember_user" do
    context "when session has a token" do
      before do
        session[:session_token] = "test_token_123"
      end

      it "sets session token in permanent cookies" do
        helper.remember_user

        expect(cookies.permanent.signed[:session_token]).to eq("test_token_123")
      end

      it "uses signed cookies for security" do
        expect(cookies.permanent).to receive(:signed).and_return({})

        helper.remember_user
      end

      it "uses permanent cookies for persistence" do
        expect(cookies).to receive(:permanent).and_return(double.as_null_object)

        helper.remember_user
      end
    end

    context "when session has no token" do
      it "does nothing" do
        helper.remember_user

        expect(cookies.permanent.signed[:session_token]).to be_nil
      end
    end
  end

  describe "#forget_user" do
    it "deletes session token from cookies" do
      cookies.signed[:session_token] = "test_token"

      helper.forget_user

      expect(cookies.signed[:session_token]).to be_nil
    end
  end

  describe "#current_user" do
    context "when session has a valid token" do
      before do
        session[:session_token] = user_session.session_token
      end

      it "returns the user" do
        expect(helper.current_user).to eq(user)
      end

      it "memoizes the result" do
        expect(UserSession).to receive(:find_by).once.and_return(user_session)

        2.times { helper.current_user }
      end
    end

    context "when session has an invalid token" do
      before do
        session[:session_token] = "invalid_token"
      end

      it "returns nil" do
        expect(helper.current_user).to be_nil
      end

      it "clears the invalid token from session" do
        helper.current_user
        expect(session[:session_token]).to be_nil
      end
    end

    context "when cookies has a valid token but session does not" do
      before do
        cookies.signed[:session_token] = user_session.session_token
      end

      it "restores session and returns the user" do
        expect(helper.current_user).to eq(user)
        expect(session[:session_token]).to eq(user_session.session_token)
      end
    end

    context "when cookies has an invalid token" do
      before do
        cookies.signed[:session_token] = "invalid_cookie_token"
      end

      it "returns nil" do
        expect(helper.current_user).to be_nil
      end

      it "clears the invalid token from cookies" do
        helper.current_user
        expect(cookies.signed[:session_token]).to be_nil
      end
    end

    context "when neither session nor cookies has a token" do
      it "returns nil" do
        expect(helper.current_user).to be_nil
      end
    end
  end

  describe "#logged_in?" do
    it "returns true when current_user exists" do
      allow(helper).to receive(:current_user).and_return(user)

      expect(helper.logged_in?).to be true
    end

    it "returns false when current_user is nil" do
      allow(helper).to receive(:current_user).and_return(nil)

      expect(helper.logged_in?).to be false
    end
  end

  describe "#log_out" do
    before do
      session[:session_token] = "test_token"
      session[:original_admin_id] = "admin_id"
      cookies.signed[:session_token] = "test_token"
      allow(helper).to receive(:current_user).and_return(user)
    end

    it "deletes session token from session" do
      helper.log_out

      expect(session[:session_token]).to be_nil
    end

    it "deletes admin impersonation tracking" do
      helper.log_out

      expect(session[:original_admin_id]).to be_nil
    end

    it "forgets the user" do
      expect(helper).to receive(:forget_user)

      helper.log_out
    end

    it "sets current_user to nil" do
      helper.log_out

      expect(helper.instance_variable_get(:@current_user)).to be_nil
    end

    it "handles nil session gracefully" do
      allow(session).to receive(:[]).with(:session_token).and_return(nil)

      expect { helper.log_out }.not_to raise_error
    end
  end

  describe "#create_user_session" do
    it "remembers the user" do
      expect(helper).to receive(:remember_user)

      helper.create_user_session
    end
  end

  describe "#authenticate_user" do
    it "returns user when email and password are correct" do
      user = create(:user, email: "test@example.com", password: "password123")

      result = helper.authenticate_user("test@example.com", "password123")
      expect(result).to eq(user)
    end

    it "returns nil when email is blank" do
      result = helper.authenticate_user("", "password123")
      expect(result).to be_nil
    end

    it "returns nil when password is blank" do
      result = helper.authenticate_user("test@example.com", "")
      expect(result).to be_nil
    end

    it "returns nil when user not found" do
      result = helper.authenticate_user("nonexistent@example.com", "password")
      expect(result).to be_nil
    end

    it "returns false when password is incorrect" do
      user_params = {
        email: "test@example.com",
        password: "correct_password",
        password_confirmation: "correct_password"
      }
      create(:user, user_params)

      result = helper.authenticate_user("test@example.com", "wrong_password")
      expect(result).to eq(false)
    end

    it "is case-insensitive for email" do
      user = create(:user, email: "test@example.com", password: "password123")

      result = helper.authenticate_user("TEST@EXAMPLE.COM", "password123")
      expect(result).to eq(user)
    end
  end

  describe "#current_session" do
    context "when session has a valid token" do
      before do
        session[:session_token] = user_session.session_token
      end

      it "returns the UserSession" do
        expect(helper.current_session).to eq(user_session)
      end
    end

    context "when session has no token" do
      it "returns nil" do
        expect(helper.current_session).to be_nil
      end
    end

    context "when session has invalid token" do
      before do
        session[:session_token] = "invalid_token"
      end

      it "returns nil" do
        expect(helper.current_session).to be_nil
      end
    end
  end

  describe "Security considerations" do
    it "does not authenticate with a malicious session token" do
      session[:session_token] = "malicious_input'; DROP TABLE users; --"

      expect(helper.current_user).to be_nil
    end

    it "does not authenticate with a tampered cookie" do
      cookies[:session_token] = user_session.session_token

      expect(helper.current_user).to be_nil
    end

    it "safely handles cookie tampering attempts" do
      cookies.signed[:session_token] = "not_a_valid_token"

      expect { helper.current_user }.not_to raise_error
      expect(helper.current_user).to be_nil
    end

    it "handles SQL injection attempts via session token" do
      malicious_token = "1; DELETE FROM user_sessions; --"
      session[:session_token] = malicious_token

      expect(helper.current_user).to be_nil
    end
  end
end
