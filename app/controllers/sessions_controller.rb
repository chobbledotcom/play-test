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
        flash[:notice] = I18n.t("session.login.success")
        redirect_to inspections_path
        return
      end
    end

    flash.now[:alert] = I18n.t("session.login.error")
    render :new, status: :unprocessable_entity
  end

  def destroy
    log_out
    flash[:notice] = I18n.t("session.logout.success")
    redirect_to root_path
  end
end
