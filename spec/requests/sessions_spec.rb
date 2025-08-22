# typed: false

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
      # Clean up any existing sessions first
      UserSession.destroy_all
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

  describe "GET /passkey_login" do
    context "when not logged in" do
      it "returns WebAuthn options for authentication" do
        # Create some existing credentials for the test
        credential1 = create(:credential)
        credential2 = create(:credential)

        get "/passkey_login", headers: {"Accept" => "application/json"}

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        # Check that the response contains WebAuthn options
        expect(json_response).to have_key("challenge")
        expect(json_response).to have_key("timeout")
        expect(json_response).to have_key("userVerification")
        expect(json_response["userVerification"]).to eq("required")

        # Check that all credentials are included
        expect(json_response).to have_key("allowCredentials")
        expect(json_response["allowCredentials"]).to be_an(Array)
        expect(json_response["allowCredentials"].length).to eq(2)

        credential_ids = json_response["allowCredentials"].map { |c| c["id"] }
        expect(credential_ids).to include(credential1.external_id)
        expect(credential_ids).to include(credential2.external_id)

        json_response["allowCredentials"].each do |cred|
          expect(cred["type"]).to eq("public-key")
        end
      end

      it "returns empty allowCredentials when no credentials exist" do
        get "/passkey_login", headers: {"Accept" => "application/json"}

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["allowCredentials"]).to eq([])
      end
    end

    context "when already logged in" do
      let(:user) { create(:user) }

      before do
        login_as(user)
      end

      it "redirects to inspections path" do
        get "/passkey_login"

        expect(response).to redirect_to(inspections_path)
      end
    end
  end

  describe "POST /passkey_callback" do
    let(:user) { create(:user) }
    let(:credential) { create(:credential, user: user, sign_count: 5) }
    let(:challenge) { SecureRandom.hex(32) }

    def setup_passkey_session
      # First call the passkey endpoint to set up the session
      get "/passkey_login", headers: {"Accept" => "application/json"}
      json_response = JSON.parse(response.body)
      json_response["challenge"]
    end

    context "with valid passkey authentication" do
      it "authenticates user and creates session" do
        # Set up session by calling passkey endpoint first
        challenge = setup_passkey_session

        # Mock WebAuthn credential
        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: Base64.strict_decode64(credential.external_id),
          sign_count: 6
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_return(true)

        expect {
          post "/passkey_callback", params: {
            id: credential.external_id,
            type: "public-key",
            rawId: credential.external_id,
            response: {
              authenticatorData: "test_data",
              clientDataJSON: "test_client_data",
              signature: "test_signature"
            }
          }
        }.to change { UserSession.count }.by(1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("ok")

        # Check credential sign count was updated
        expect(credential.reload.sign_count).to eq(6)

        # Check user session was created
        user_session = UserSession.last
        expect(user_session.user_id).to eq(user.id)
      end

      it "creates session for successful authentication" do
        setup_passkey_session

        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: Base64.strict_decode64(credential.external_id),
          sign_count: 6
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_return(true)

        post "/passkey_callback", params: {id: credential.external_id}

        expect(response).to have_http_status(:ok)
        expect(UserSession.last.user_id).to eq(user.id)
      end
    end

    context "when credential not found" do
      it "returns error for non-existent credential" do
        setup_passkey_session

        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: "nonexistent_id"
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)

        post "/passkey_callback", params: {id: "invalid_credential_id"}

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include(I18n.t("sessions.messages.passkey_not_found"))

        # Session should NOT be created
        expect(UserSession.count).to eq(0)
      end
    end

    context "when verification fails" do
      it "returns error and does not create session" do
        setup_passkey_session

        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: Base64.strict_decode64(credential.external_id),
          sign_count: 6
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_raise(
          WebAuthn::VerificationError, "Invalid signature"
        )

        expect {
          post "/passkey_callback", params: {id: credential.external_id}
        }.not_to change { UserSession.count }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("sessions.messages.passkey_login_failed"))
        expect(response.body).to include("Invalid signature")

        # Credential sign count should NOT be updated
        expect(credential.reload.sign_count).to eq(5)
      end

      it "does not update credential on failure" do
        setup_passkey_session

        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: Base64.strict_decode64(credential.external_id)
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_raise(
          WebAuthn::Error, "Verification failed"
        )

        post "/passkey_callback", params: {id: credential.external_id}

        expect(response).to have_http_status(:unprocessable_content)
        expect(credential.reload.sign_count).to eq(5)
      end
    end

    context "when user verification is not satisfied" do
      it "returns error when user verification fails" do
        setup_passkey_session

        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: Base64.strict_decode64(credential.external_id)
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_raise(
          WebAuthn::UserVerifiedVerificationError, "User verification required"
        )

        post "/passkey_callback", params: {id: credential.external_id}

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("sessions.messages.passkey_login_failed"))
        expect(response.body).to include("User verification required")
      end
    end

    context "when sign count validation fails" do
      it "handles sign count mismatch" do
        setup_passkey_session

        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: Base64.strict_decode64(credential.external_id),
          sign_count: 3 # Lower than stored sign_count of 5
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_raise(
          WebAuthn::SignCountVerificationError, "Sign count verification failed"
        )

        post "/passkey_callback", params: {id: credential.external_id}

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("sessions.messages.passkey_login_failed"))
      end
    end

    context "when already logged in" do
      before do
        login_as(user)
      end

      it "redirects to inspections path" do
        post "/passkey_callback", params: {id: credential.external_id}

        expect(response).to redirect_to(inspections_path)
      end
    end

    context "with multiple credentials for same user" do
      let(:credential2) { create(:credential, user: user, sign_count: 10) }

      it "authenticates with the correct credential" do
        setup_passkey_session

        mock_webauthn_credential = instance_double(
          WebAuthn::PublicKeyCredential,
          raw_id: Base64.strict_decode64(credential2.external_id),
          sign_count: 11
        )

        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_return(true)

        post "/passkey_callback", params: {id: credential2.external_id}

        expect(response).to have_http_status(:ok)

        # Only credential2 should be updated
        expect(credential2.reload.sign_count).to eq(11)
        expect(credential.reload.sign_count).to eq(5) # Unchanged
      end
    end
  end
end
