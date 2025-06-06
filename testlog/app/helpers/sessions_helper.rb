module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def remember_user
    cookies.permanent.signed[:user_id] = current_user.id if current_user
  end

  def forget_user
    cookies.delete(:user_id)
  end

  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    elsif cookies.signed[:user_id]
      user = User.find_by(id: cookies.signed[:user_id])
      if user
        log_in user
        @current_user = user
      end
    end
  end

  def logged_in?
    !current_user.nil?
  end

  def log_out
    session.delete(:user_id)
    forget_user
    @current_user = nil
  end
end
