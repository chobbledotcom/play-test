# typed: false

require "rails_helper"

RSpec.describe CredentialsController, type: :controller do
  let(:user) { create(:user) }
  let(:credential) { create(:credential, user: user) }

  # Helper to simulate logged in user for controller specs
  define_method(:sign_in_user) do |user|
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in?).and_return(true)
  end

  # Helper to simulate logged out state
  define_method(:sign_out_user) do
    allow(controller).to receive(:current_user).and_return(nil)
    allow(controller).to receive(:logged_in?).and_return(false)
  end

  # Helper to mock WebAuthn credential creation options
  define_method(:mock_creation_options) do |challenge: "test-challenge"|
    double(
      challenge: challenge,
      to_json: {challenge: challenge}.to_json
    )
  end

  # Helper to mock WebAuthn credential from client
  define_method(:mock_webauthn_credential) do |**opts|
    defaults = {
      raw_id: "test-raw-id",
      public_key: "test-public-key",
      sign_count: 42
    }
    options = defaults.merge(opts)
    double(
      "WebAuthn::Credential",
      raw_id: options[:raw_id],
      public_key: options[:public_key],
      sign_count: options[:sign_count],
      verify: true
    )
  end

  # Helper to setup session with challenge
  define_method(:setup_challenge_session) do |challenge = "test-challenge"|
    session[:current_registration] = {"challenge" => challenge}
  end

  before do
    sign_in_user(user)
  end

  describe "#create" do
    it "sets challenge in session" do
      mock_options = mock_creation_options(challenge: "test-challenge-123")
      allow(WebAuthn::Credential).to receive(:options_for_create)
        .and_return(mock_options)

      post :create, format: :json

      expect(session[:current_registration]).to eq(
        {challenge: "test-challenge-123"}
      )
    end

    it "excludes existing credentials from options" do
      credential1 = create(:credential, user: user,
        external_id: "existing-1")
      credential2 = create(:credential, user: user,
        external_id: "existing-2")

      expect(WebAuthn::Credential).to receive(:options_for_create).with(
        hash_including(
          exclude: [credential1.external_id, credential2.external_id]
        )
      ).and_return(mock_creation_options)

      post :create, format: :json
    end

    it "includes correct user data in options" do
      expect(WebAuthn::Credential).to receive(:options_for_create).with(
        hash_including(
          user: {
            id: user.webauthn_id,
            name: user.email
          }
        )
      ).and_return(mock_creation_options)

      post :create, format: :json
    end

    it "requires user verification in authenticator selection" do
      expect(WebAuthn::Credential).to receive(:options_for_create).with(
        hash_including(
          authenticator_selection: {
            user_verification: "required"
          }
        )
      ).and_return(mock_creation_options)

      post :create, format: :json
    end

    it "responds with JSON format" do
      mock_options = mock_creation_options
      allow(WebAuthn::Credential).to receive(:options_for_create)
        .and_return(mock_options)

      post :create, format: :json

      expect(response.content_type).to match(/json/)
    end
  end

  describe "#callback" do
    let(:mock_credential) { mock_webauthn_credential }

    before do
      setup_challenge_session
      allow(WebAuthn::Credential).to receive(:from_create)
        .and_return(mock_credential)
    end

    context "when verification succeeds" do
      it "creates new credential with correct attributes" do
        post :callback, params: {credential_nickname: "My Passkey"}

        external_id = Base64.strict_encode64("test-raw-id")
        new_credential = user.credentials.find_by(
          external_id: external_id
        )
        expect(new_credential).to be_present
        expect(new_credential.nickname).to eq("My Passkey")
        expect(new_credential.public_key).to eq("test-public-key")
        expect(new_credential.sign_count).to eq(42)
      end

      it "updates existing credential if external_id matches" do
        existing = create(:credential,
          user: user,
          external_id: Base64.strict_encode64("test-raw-id"),
          nickname: "Old Name",
          sign_count: 10)

        post :callback, params: {credential_nickname: "Updated Name"}

        existing.reload
        expect(existing.nickname).to eq("Updated Name")
        expect(existing.sign_count).to eq(42)
      end

      it "verifies with correct challenge from session" do
        expect(mock_credential).to receive(:verify).with(
          "test-challenge", user_verification: true
        )

        post :callback, params: {credential_nickname: "Test"}
      end

      it "clears session registration data after success" do
        post :callback, params: {credential_nickname: "Test"}

        expect(session[:current_registration]).to be_nil
      end

      it "responds with success JSON" do
        post :callback, params: {credential_nickname: "Test"}

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({"status" => "ok"})
      end
    end

    context "when verification fails" do
      before do
        allow(WebAuthn::Credential).to receive(:from_create)
          .and_raise(WebAuthn::Error, "Invalid signature")
      end

      it "returns unprocessable content status" do
        post :callback, params: {credential_nickname: "Test"}

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "includes error message in response" do
        post :callback, params: {credential_nickname: "Test"}

        expected_msg = I18n.t("credentials.messages.verification_failed")
        expect(response.body).to include(expected_msg)
        expect(response.body).to include("Invalid signature")
      end

      it "clears session registration data on error" do
        post :callback, params: {credential_nickname: "Test"}

        expect(session[:current_registration]).to be_nil
      end
    end

    context "when credential save fails" do
      before do
        allow_any_instance_of(Credential).to receive(:update)
          .and_return(false)
      end

      it "returns unprocessable content status" do
        post :callback, params: {credential_nickname: "Test"}

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns appropriate error message" do
        post :callback, params: {credential_nickname: "Test"}

        expected_msg = I18n.t("credentials.messages.could_not_add")
        expect(response.body).to eq(expected_msg)
      end

      it "clears session registration data" do
        post :callback, params: {credential_nickname: "Test"}

        expect(session[:current_registration]).to be_nil
      end
    end

    context "when session challenge is missing" do
      before do
        session.delete(:current_registration)
        allow(WebAuthn::Credential).to receive(:from_create)
          .and_raise(WebAuthn::Error, "Challenge verification failed")
      end

      it "handles missing session data gracefully" do
        post :callback, params: {credential_nickname: "Test"}

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(
          I18n.t("credentials.messages.verification_failed")
        )
      end
    end
  end

  describe "#destroy" do
    context "when user can delete credentials" do
      let!(:credential1) { create(:credential, user: user) }
      let!(:credential2) { create(:credential, user: user) }

      it "deletes credential and redirects with success message" do
        expect {
          delete :destroy, params: {id: credential1.id}
        }.to change(user.credentials, :count).by(-1)

        expect(Credential.exists?(credential1.id)).to be false
        expect(flash[:notice]).to eq(I18n.t("credentials.messages.deleted"))
        expect(response).to redirect_to(change_settings_user_path(user))
      end
    end

    context "when user cannot delete credentials" do
      let!(:only_credential) { create(:credential, user: user) }

      before do
        allow(user).to receive(:can_delete_credentials?)
          .and_return(false)
      end

      it "prevents deletion and redirects with error message" do
        expect {
          delete :destroy, params: {id: only_credential.id}
        }.not_to change(user.credentials, :count)

        expect(Credential.exists?(only_credential.id)).to be true
        expected_msg = I18n.t("credentials.messages.cannot_delete_last")
        expect(flash[:error]).to eq(expected_msg)
        expect(response).to redirect_to(change_settings_user_path(user))
      end
    end

    context "when credential belongs to another user" do
      let(:other_user) { create(:user) }
      let(:other_credential) { create(:credential, user: other_user) }

      it "raises RecordNotFound error" do
        expect {
          delete :destroy, params: {id: other_credential.id}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when credential does not exist" do
      it "raises RecordNotFound error" do
        expect {
          delete :destroy, params: {id: 999999}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "authentication requirements" do
    before do
      sign_out_user
    end

    it "redirects to login for create action" do
      post :create, format: :json
      expect(response).to redirect_to(login_path)
    end

    it "redirects to login for callback action" do
      post :callback
      expect(response).to redirect_to(login_path)
    end

    it "redirects to login for destroy action" do
      delete :destroy, params: {id: 1}
      expect(response).to redirect_to(login_path)
    end
  end
end
