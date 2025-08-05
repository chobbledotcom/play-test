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

  private

  def handle_successful_login(user)
    should_remember = params.dig(:session, :remember_me) == "1"
    user_session = create_session_record(user)

    create_user_session(user, should_remember)
    session[:session_token] = user_session.session_token

    flash[:notice] = I18n.t("session.login.success")
    redirect_to inspections_path
  end

  def create_session_record(user)
    Rails.logger.info "Creating user session for user #{user.id}"
    Rails.logger.info "User exists in DB: #{User.exists?(user.id)}"
    Rails.logger.info "User sessions count before: #{user.user_sessions.count}"

    user_session = user.user_sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      last_active_at: Time.current
    )
    Rails.logger.info "User session created: #{user_session.id}"
    user_session
  rescue => e
    Rails.logger.error "Failed to create user session: #{e.message}"
    Rails.logger.error "User ID: #{user.id}, class: #{user.id.class}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
