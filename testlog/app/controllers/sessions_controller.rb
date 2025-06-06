class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create, :destroy]

  def new
  end

  def create
    email = params.dig(:session, :email)
    password = params.dig(:session, :password)

    if email.present?
      user = User.find_by(email: email.downcase)
      if user&.authenticate(password)
        log_in user
        if params[:session][:remember_me] == "1"
          cookies.permanent.signed[:user_id] = user.id
        else
          cookies.delete(:user_id)
        end
        flash[:success] = "Logged in"
        redirect_to root_path
        return
      end
    end

    flash.now[:danger] = "Invalid email/password combination"
    render :new, status: :unprocessable_entity
  end

  def destroy
    log_out
    flash[:success] = "Logged out"
    redirect_to root_path
  end
end
