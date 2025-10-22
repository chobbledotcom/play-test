# typed: strict
# frozen_string_literal: true

module SessionManagement
  extend T::Sig
  extend T::Helpers
  extend ActiveSupport::Concern

  private

  sig { params(user: User).returns(UserSession) }
  def establish_user_session(user)
    user_session = user.user_sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      last_active_at: Time.current
    )

    session[:session_token] = user_session.session_token
    create_user_session

    user_session
  end

  sig { void }
  def terminate_current_session
    return unless session[:session_token]

    UserSession.find_by(session_token: session[:session_token])&.destroy
    session.delete(:session_token)
  end
end
