# typed: strict
# frozen_string_literal: true

module SessionsHelper
  extend T::Sig

  sig { params(user: User).void }
  def log_in(user)
    session[:user_id] = user.id
  end

  sig { void }
  def remember_user
    if current_user
      cookies.permanent.signed[:user_id] = current_user.id
    end
  end

  sig { void }
  def forget_user
    cookies.delete(:user_id)
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
    elsif session[:user_id]
      User.find_by(id: session[:user_id])
    elsif cookies.signed[:user_id]
      user_from_cookie
    end
  end

  sig { returns(T.nilable(User)) }
  def user_from_session_token
    user_session = UserSession.find_by(session_token: session[:session_token])
    if user_session
      user_session.user
    else
      # Session token is invalid, clear session
      session.delete(:user_id)
      session.delete(:session_token)
      nil
    end
  end

  sig { returns(T.nilable(User)) }
  def user_from_cookie
    user = User.find_by(id: cookies.signed[:user_id])
    return unless user
    log_in user
    user
  end

  public

  sig { returns(T::Boolean) }
  def logged_in?
    !current_user.nil?
  end

  sig { void }
  def log_out
    session.delete(:user_id)
    session.delete(:original_admin_id)  # Clear impersonation tracking
    forget_user
    @current_user = nil
  end

  sig {
    params(
      email: T.nilable(String),
      password: T.nilable(String)
    ).returns(T.nilable(T.any(User, T::Boolean)))
  }
  def authenticate_user(email, password)
    return nil unless email.present? && password.present?
    User.find_by(email: email.downcase)&.authenticate(password)
  end

  sig { params(user: User, should_remember: T::Boolean).void }
  def create_user_session(user, should_remember = false)
    log_in user
    remember_user if should_remember
  end

  sig { returns(T.nilable(UserSession)) }
  def current_session
    return unless session[:session_token]
    @current_session ||= UserSession.find_by(
      session_token: session[:session_token]
    )
  end
end
