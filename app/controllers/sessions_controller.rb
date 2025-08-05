class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create, :destroy]
  before_action :require_logged_out, only: [:new, :create]

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
      render :new, status: :unprocessable_entity
    end
  end

  private

  def handle_successful_login(user)
    should_remember = params.dig(:session, :remember_me) == "1"
    create_user_session(user, should_remember)
    # Create UserSession record
    user_session = user.user_sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      last_active_at: Time.current
    )
    session[:session_token] = user_session.session_token
    flash[:notice] = I18n.t("session.login.success")
    redirect_to inspections_path
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
end
