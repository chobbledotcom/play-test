module ChobbleApp
  class SessionsController < ApplicationController
    skip_before_action :require_login, only: [:new, :create, :destroy]
    before_action :require_logged_out, only: [:new, :create]

    def new
    end

    def create
      sleep(rand(0.5..1.0)) unless Rails.env.test?

      email = params.dig(:session, :email)
      password = params.dig(:session, :password)

      if (user = authenticate_user(email, password))
        should_remember = params.dig(:session, :remember_me) == "1"
        create_user_session(user, should_remember)
        flash[:notice] = I18n.t("session.login.success")
        redirect_to after_login_path
      else
        flash.now[:alert] = I18n.t("session.login.error")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      log_out
      flash[:notice] = I18n.t("session.logout.success")
      redirect_to root_path
    end

    private

    def after_login_path
      root_path # Override in main app
    end
  end
end
