# typed: false
# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login,
    only: [:new, :create, :destroy, :passkey, :passkey_callback]
  before_action :require_logged_out,
    only: [:new, :create, :passkey, :passkey_callback]

  def new
  end

  def create
    sleep(rand(0.5..1.0)) unless Rails.env.test?

    email = params.dig(:session, :email)
    password = params.dig(:session, :password)

    if (user = authenticate_user(email, password))
      handle_successful_login(user)
    else
      flash.now[:alert] = I18n.t("session.login.error")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    # Delete current session record
    if session[:session_token]
      UserSession.find_by(session_token: session[:session_token])&.destroy
    end
    session.delete(:session_token)
    log_out
    flash[:notice] = I18n.t("session.logout.success")
    redirect_to root_path
  end

  def passkey
    # Get all credentials for this RP to help password managers
    all_credentials = Credential.all.map do |cred|
      {
        id: cred.external_id,
        type: "public-key"
      }
    end

    # Initiate passkey authentication
    get_options = WebAuthn::Credential.options_for_get(
      user_verification: "required",
      allow_credentials: all_credentials
    )

    session[:passkey_authentication] = {challenge: get_options.challenge}

    render json: get_options
  end

  def passkey_callback
    webauthn_credential = WebAuthn::Credential.from_get(params)
    credential = find_credential(webauthn_credential)

    if credential
      verify_and_sign_in_with_passkey(credential, webauthn_credential)
    else
      render json: {errors: [I18n.t("sessions.messages.passkey_not_found")]},
        status: :unprocessable_content
    end
  end

  private

  def find_credential(webauthn_credential)
    encoded_id = Base64.strict_encode64(webauthn_credential.raw_id)
    Credential.find_by(external_id: encoded_id)
  end

  def verify_and_sign_in_with_passkey(credential, webauthn_credential)
    challenge = session[:passkey_authentication]["challenge"]
    webauthn_credential.verify(
      challenge,
      public_key: credential.public_key,
      sign_count: credential.sign_count,
      user_verification: true
    )

    credential.update!(sign_count: webauthn_credential.sign_count)
    user = User.find(credential.user_id)

    # Create session for passkey login
    user_session = create_session_record(user)
    create_user_session(user, true)
    session[:session_token] = user_session.session_token

    render json: {status: "ok"}, status: :ok
  rescue WebAuthn::Error => e
    error_msg = I18n.t("sessions.messages.passkey_login_failed")
    render json: "#{error_msg}: #{e.message}",
      status: :unprocessable_content
  ensure
    session.delete(:passkey_authentication)
  end

  def handle_successful_login(user)
    should_remember = params.dig(:session, :remember_me) == "1"
    user_session = create_session_record(user)

    create_user_session(user, should_remember)
    session[:session_token] = user_session.session_token

    flash[:notice] = I18n.t("session.login.success")
    redirect_to inspections_path
  end

  def create_session_record(user)
    user.user_sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      last_active_at: Time.current
    )
  end
end
