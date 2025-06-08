class UsersController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :require_admin, only: [:index, :edit, :update, :destroy, :impersonate]
  before_action :set_user, only: [:edit, :update, :destroy, :change_password, :update_password, :change_settings, :update_settings, :impersonate]
  before_action :require_correct_user, only: [:change_password, :update_password, :change_settings, :update_settings]

  def index
    @users = User.includes(:inspections).all
    @active_jobs = {
      storage_cleanup: {
        name: "StorageCleanupJob",
        scheduled: StorageCleanupJob.scheduled?,
        last_run: StorageCleanupJob.last_run_at,
        next_run: StorageCleanupJob.next_run_at
      }
    }
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      if Rails.env.production?
        NtfyService.notify("new user: #{@user.email}")
      end

      log_in @user
      flash[:success] = I18n.t("users.messages.account_created")
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:success] = I18n.t("users.messages.user_updated")
      redirect_to users_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    flash[:success] = I18n.t("users.messages.user_deleted")
    redirect_to users_path
  end

  def change_password
  end

  def update_password
    if @user.authenticate(params[:user][:current_password])
      if @user.update(password_params)
        flash[:success] = I18n.t("users.messages.password_updated")
        redirect_to root_path
      else
        render :change_password, status: :unprocessable_entity
      end
    else
      @user.errors.add(:current_password, I18n.t("activerecord.errors.models.user.attributes.current_password.incorrect"))
      render :change_password, status: :unprocessable_entity
    end
  end

  def impersonate
    log_in @user
    flash[:success] = I18n.t("users.messages.impersonating", email: @user.email)
    redirect_to root_path
  end

  def change_settings
  end

  def update_settings
    if @user.update(settings_params)
      flash[:success] = I18n.t("users.messages.settings_updated")
      redirect_to root_path
    else
      render :change_settings, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    if current_user&.admin?
      params.require(:user).permit(:email, :password, :password_confirmation, :inspection_limit, :inspection_company_id)
    else
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end

  # Using require_admin from ApplicationController

  def require_correct_user
    unless current_user == @user
      action = action_name.include?("password") ? "password" : "settings"
      flash[:danger] = I18n.t("users.messages.own_action_only", action: action)
      redirect_to root_path
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def settings_params
    params.require(:user).permit(:time_display)
  end
end
