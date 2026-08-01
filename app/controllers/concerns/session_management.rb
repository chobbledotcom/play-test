# typed: strict
# frozen_string_literal: true

module SessionManagement
  extend T::Sig
  extend T::Helpers
  extend ActiveSupport::Concern

  private

  sig { params(user: User, remember: T::Boolean).returns(UserSession) }
  def establish_user_session(user, remember: false)
    user_session = user.user_sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      last_active_at: Time.current
    )

    session[:session_token] = user_session.session_token
    @current_session = user_session
    create_user_session(remember: remember)

    user_session
  end

  sig { params(user: User).void }
  def rotate_user_sessions(user)
    remember = remembered_user?
    user.user_sessions.destroy_all
    session.delete(:session_token)
    establish_user_session(user, remember: remember)
  end

  sig { void }
  def terminate_current_session
    return unless session[:session_token]

    UserSession.find_by(session_token: session[:session_token])&.destroy
    session.delete(:session_token)
  end
end
