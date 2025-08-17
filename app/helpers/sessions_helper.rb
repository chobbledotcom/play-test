# typed: strict
# frozen_string_literal: true

module SessionsHelper
  extend T::Sig

  sig { void }
  def remember_user
    if session[:session_token]
      cookies.permanent.signed[:session_token] = session[:session_token]
    end
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
    user_session = UserSession.find_by(session_token: session[:session_token])
    if user_session
      user_session.user
    else
      # Session token is invalid, clear session
      session.delete(:session_token)
      nil
    end
  end

  sig { returns(T.nilable(User)) }
  def user_from_cookie_token
    token = cookies.signed[:session_token]
    return unless token

    user_session = UserSession.find_by(session_token: token)
    if user_session
      # Restore session from cookie
      session[:session_token] = token
      user_session.user
    else
      # Invalid cookie token, clear it
      cookies.delete(:session_token)
      nil
    end
  end

  public

  sig { returns(T::Boolean) }
  def logged_in?
    !current_user.nil?
  end

  sig { void }
  def log_out
    session.delete(:session_token)
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

  sig { params(user: User).void }
  def create_user_session(user)
    remember_user
  end

  sig { returns(T.nilable(UserSession)) }
  def current_session
    return unless session[:session_token]
    @current_session ||= UserSession.find_by(
      session_token: session[:session_token]
    )
  end
end
