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
      should_remember = params.dig(:session, :remember_me) == "1"
      create_user_session(user, should_remember)
      flash[:notice] = I18n.t("session.login.success")
      redirect_to inspections_path
    else
      flash.now[:alert] = I18n.t("session.login.error")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
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
        status: :unprocessable_entity
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
    create_user_session(user, true)

    render json: {status: "ok"}, status: :ok
  rescue WebAuthn::Error => e
    error_msg = I18n.t("sessions.messages.passkey_login_failed")
    render json: "#{error_msg}: #{e.message}",
      status: :unprocessable_entity
  ensure
    session.delete(:passkey_authentication)
  end
end
