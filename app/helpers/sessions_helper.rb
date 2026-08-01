# typed: strict
# frozen_string_literal: true

module SessionsHelper
  extend T::Sig
  include ControllerContext

  DUMMY_PASSWORD_DIGEST = BCrypt::Password.create(
    "invalid-password",
    cost: ActiveModel::SecurePassword.min_cost ?
      BCrypt::Engine::MIN_COST :
      BCrypt::Engine.cost
  )

  sig { void }
  def remember_user
    return unless session[:session_token]

    cookies.signed[:session_token] = {
      value: session[:session_token],
      expires: UserSession::INACTIVITY_TIMEOUT.from_now,
      httponly: true,
      secure: request.ssl?,
      same_site: :lax
    }
  end

  sig { void }
  def forget_user
    cookies.delete(:session_token)
  end

  sig { returns(T.nilable(User)) }
  def current_user
    @current_user ||= fetch_current_user
  end

  private

  sig { returns(T.nilable(User)) }
  def fetch_current_user
    if session[:session_token]
      user_from_session_token
    elsif cookies.signed[:session_token]
      user_from_cookie_token
    end
  end

  sig { returns(T.nilable(User)) }
  def user_from_session_token
    user_session = active_user_session_for(session[:session_token])
    if user_session
      user_session.user
    else
      clear_session_credentials
      nil
    end
  end

  sig { returns(T.nilable(User)) }
  def user_from_cookie_token
    token = cookies.signed[:session_token]
    return unless token

    user_session = active_user_session_for(token)
    if user_session
      session[:session_token] = token
      remember_user
      user_session.user
    else
      clear_session_credentials
      nil
    end
  end

  sig { params(token: T.nilable(String)).returns(T.nilable(UserSession)) }
  def active_user_session_for(token)
    return unless token

    user_session = UserSession.find_by(session_token: token)
    return unless user_session
    return user_session if user_session.active?

    user_session.destroy
    nil
  end

  sig { void }
  def clear_session_credentials
    session.delete(:session_token)
    forget_user
    @current_session = nil
  end

  public

  sig { returns(T::Boolean) }
  def logged_in?
    !current_user.nil?
  end

  sig { void }
  def log_out
    session.delete(:session_token)
    session.delete(:original_admin_id) # Clear impersonation tracking
    forget_user
    @current_user = nil
  end

  sig do
    params(
      email: T.nilable(String),
      password: T.nilable(String)
    ).returns(T.nilable(T.any(User, T::Boolean)))
  end
  def authenticate_user(email, password)
    return nil unless email.present? && password.present?

    user = User.find_by(email: email.downcase)
    return user.authenticate(password) if user

    BCrypt::Password.new(DUMMY_PASSWORD_DIGEST).is_password?(password)
    nil
  end

  sig { params(remember: T::Boolean).void }
  def create_user_session(remember: false)
    remember ? remember_user : forget_user
  end

  sig { returns(T::Boolean) }
  def remembered_user?
    cookies.signed[:session_token].present?
  end

  sig { returns(T.nilable(UserSession)) }
  def current_session
    return unless session[:session_token]

    @current_session ||= active_user_session_for(session[:session_token])
  end
end
