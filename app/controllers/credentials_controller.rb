class CredentialsController < ApplicationController
  before_action :require_login

  def create
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_id,
        name: current_user.email
      },
      exclude: current_user.credentials.pluck(:external_id),
      authenticator_selection: {user_verification: "required"}
    )

    session[:current_registration] = {challenge: create_options.challenge}

    respond_to do |format|
      format.json { render json: create_options }
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_create(params)
    verify_and_save_credential(webauthn_credential)
  rescue WebAuthn::Error => e
    error_msg = I18n.t("credentials.messages.verification_failed")
    render json: "#{error_msg}: #{e.message}",
      status: :unprocessable_entity
  ensure
    session.delete(:current_registration)
  end

  def destroy
    credential = current_user.credentials.find(params[:id])

    if current_user.can_delete_credentials?
      credential.destroy
      flash[:notice] = I18n.t("credentials.messages.deleted")
    else
      flash[:error] = I18n.t("credentials.messages.cannot_delete_last")
    end

    redirect_to change_settings_user_path(current_user)
  end

  private

  def verify_and_save_credential(webauthn_credential)
    challenge = session[:current_registration]["challenge"]
    webauthn_credential.verify(challenge, user_verification: true)

    credential = current_user.credentials.find_or_initialize_by(
      external_id: Base64.strict_encode64(webauthn_credential.raw_id)
    )

    credential_attrs = credential_params(webauthn_credential)
    # Ensure user_id is set for new records
    credential_attrs[:user_id] = current_user.id if credential.new_record?

    if credential.update(credential_attrs)
      render json: {status: "ok"}, status: :ok
    else
      error_msg = I18n.t("credentials.messages.could_not_add")
      render json: error_msg, status: :unprocessable_entity
    end
  end

  def credential_params(webauthn_credential)
    {
      nickname: params[:credential_nickname],
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count
    }
  end
end
