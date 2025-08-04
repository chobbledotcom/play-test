module ChobbleApp
  module SessionsHelper
    def log_in(user)
      session[:user_id] = user.id
    end

    def remember_user
      if current_user
        cookies.permanent.signed[:user_id] = current_user.id
      end
    end

    def forget_user
      cookies.delete(:user_id)
    end

    def current_user
      if session[:user_id]
        @current_user ||= User.find_by(id: session[:user_id])
      elsif cookies.signed[:user_id]
        user = User.find_by(id: cookies.signed[:user_id])
        return unless user
        log_in user
        @current_user = user
      end
    end

    def logged_in?
      !current_user.nil?
    end

    def log_out
      session.delete(:user_id)
      session.delete(:original_admin_id)  # Clear impersonation tracking
      forget_user
      @current_user = nil
    end

    def authenticate_user(email, password)
      return nil unless email.present? && password.present?
      User.find_by(email: email.downcase)&.authenticate(password)
    end

    def create_user_session(user, should_remember = false)
      log_in user
      remember_user if should_remember
    end
  end
end
