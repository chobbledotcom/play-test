class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user&.authenticate(params[:session][:password])
      log_in user
      if params[:session][:remember_me] == "1"
        cookies.permanent.signed[:user_id] = user.id
      else
        cookies.delete(:user_id)
      end
      flash[:success] = "Logged in"
      redirect_to root_path
    else
      flash.now[:danger] = "Invalid email/password combination"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    flash[:success] = "Logged out"
    redirect_to root_path
  end
end
