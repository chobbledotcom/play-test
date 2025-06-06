require "rails_helper"

RSpec.describe SessionsHelper, type: :helper do
  let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }

  # Security test helpers
  def simulate_csrf_attack
    cookies[:_csrf_token] = "FAKE_TOKEN"
  end

  describe "#log_in" do
    it "sets user id in session" do
      helper.log_in(user)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "#remember_user" do
    it "sets user id in permanent cookies when user is logged in" do
      allow(helper).to receive(:current_user).and_return(user)

      helper.remember_user

      expect(cookies.permanent.signed[:user_id]).to eq(user.id)
    end

    it "does nothing when no user is logged in" do
      allow(helper).to receive(:current_user).and_return(nil)

      helper.remember_user

      expect(cookies.permanent.signed[:user_id]).to be_nil
    end

    it "uses signed cookies for security" do
      allow(helper).to receive(:current_user).and_return(user)

      expect(cookies.permanent).to receive(:signed).and_return({})

      helper.remember_user
    end

    it "uses permanent cookies for persistence" do
      allow(helper).to receive(:current_user).and_return(user)

      expect(cookies).to receive(:permanent).and_return(double.as_null_object)

      helper.remember_user
    end
  end

  describe "#forget_user" do
    it "deletes user id from cookies" do
      cookies.signed[:user_id] = user.id

      helper.forget_user

      expect(cookies.signed[:user_id]).to be_nil
    end
  end

  describe "#current_user" do
    context "when session has user id" do
      before do
        session[:user_id] = user.id
      end

      it "returns the user" do
        expect(helper.current_user).to eq(user)
      end

      it "memoizes the result" do
        expect(User).to receive(:find_by).once.and_return(user)

        2.times { helper.current_user }
      end

      it "returns nil when session contains invalid user ID" do
        session[:user_id] = 999999 # Non-existent ID
        expect(helper.current_user).to be_nil
      end
    end

    context "when cookies has user id but session does not" do
      before do
        cookies.signed[:user_id] = user.id
      end

      it "logs in the user and returns the user" do
        expect(helper).to receive(:log_in).with(user)

        expect(helper.current_user).to eq(user)
      end

      it "returns nil when cookies contain invalid user ID" do
        cookies.signed[:user_id] = 999999 # Non-existent ID
        expect(helper.current_user).to be_nil
      end

      it "returns nil when cookies contain tampered (unsigned) user ID" do
        # Simulate a tampered cookie where signed value wasn't used
        allow(cookies).to receive(:signed).and_return({})
        cookies[:user_id] = user.id  # Raw cookie without signature

        expect(helper.current_user).to be_nil
      end
    end

    context "when neither session nor cookies has user id" do
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
      session[:user_id] = user.id
      cookies.signed[:user_id] = user.id
      allow(helper).to receive(:current_user).and_return(user)
    end

    it "deletes user id from session" do
      helper.log_out

      expect(session[:user_id]).to be_nil
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
      allow(session).to receive(:[]).with(:user_id).and_return(nil)

      expect { helper.log_out }.not_to raise_error
    end
  end

  describe "Security considerations" do
    it "does not authenticate with a malicious session ID" do
      session[:user_id] = "malicious_input'; DROP TABLE users; --"

      expect(helper.current_user).to be_nil
    end

    it "does not authenticate with a tampered cookie" do
      # Using raw cookie instead of signed cookie
      cookies[:user_id] = user.id.to_s

      expect(helper.current_user).to be_nil
    end

    it "safely handles cookie tampering attempts" do
      # Set an invalid format for the cookie that might cause errors if not handled properly
      cookies.signed[:user_id] = "not_an_integer"

      expect { helper.current_user }.not_to raise_error
      expect(helper.current_user).to be_nil
    end

    it "handles SQL injection attempts via session ID" do
      malicious_id = "1; DELETE FROM users; --"
      session[:user_id] = malicious_id

      # Should handle this safely and return nil
      expect(helper.current_user).to be_nil
    end
  end
end
