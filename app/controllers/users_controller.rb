class UsersController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :require_admin, only: %i[destroy edit impersonate index update verify_rpii]
  before_action :set_user, only: %i[
    change_password
    change_settings
    destroy
    edit
    impersonate
    update
    update_password
    update_settings
    verify_rpii
  ]
  before_action :require_correct_user, only: %i[
    change_password change_settings update_password update_settings
  ]

  def index
    @users = User.includes(:inspections).all
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
      flash[:notice] = I18n.t("users.messages.account_created")
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Convert empty string to nil for inspection_company_id
    if params[:user][:inspection_company_id] == ""
      params[:user][:inspection_company_id] = nil
    end

    if @user.update(user_params)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("users.messages.user_updated")
          redirect_to users_path
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("user_edit_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "user_edit_save_message",
                success: true,
                success_message: I18n.t("users.messages.user_updated")
              })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("user_edit_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "user_edit_save_message",
                errors: @user.errors.full_messages,
                error_message: t("shared.messages.save_failed")
              })
          ]
        end
      end
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = I18n.t("users.messages.user_deleted")
    redirect_to users_path
  end

  def change_password
  end

  def update_password
    if @user.authenticate(params[:user][:current_password])
      if @user.update(password_params)
        flash[:notice] = I18n.t("users.messages.password_updated")
        redirect_to root_path
      else
        render :change_password, status: :unprocessable_entity
      end
    else
      @user.errors.add(:current_password, I18n.t("users.errors.wrong_password"))
      render :change_password, status: :unprocessable_entity
    end
  end

  def impersonate
    # Store original admin user ID before impersonating
    session[:original_admin_id] = current_user.id if current_user.admin?
    log_in @user
    flash[:notice] = I18n.t("users.messages.impersonating", email: @user.email)
    redirect_to root_path
  end

  def change_settings
  end

  def update_settings
    if @user.update(settings_params)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("users.messages.settings_updated")
          redirect_to root_path
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("user_settings_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "user_settings_save_message",
                success: true,
                success_message: I18n.t("users.messages.settings_updated")
              })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :change_settings, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("user_settings_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "user_settings_save_message",
                errors: @user.errors.full_messages,
                error_message: t("shared.messages.save_failed")
              })
          ]
        end
      end
    end
  end

  def verify_rpii
    result = @user.verify_rpii_inspector_number

    respond_to do |format|
      format.html do
        if result[:valid]
          flash[:notice] = I18n.t("users.messages.rpii_verified")
        else
          flash[:alert] = get_rpii_error_message(result)
        end
        redirect_to edit_user_path(@user)
      end

      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("rpii_verification_result",
          partial: "users/rpii_verification_result",
          locals: {result: result, user: @user})
      end
    end
  end

  private

  def get_rpii_error_message(result)
    case result[:error]
    when :blank_number
      I18n.t("users.messages.rpii_blank_number")
    when :blank_name
      I18n.t("users.messages.rpii_blank_name")
    when :name_mismatch
      inspector = result[:inspector]
      I18n.t("users.messages.rpii_name_mismatch",
        user_name: @user.name,
        inspector_name: inspector[:name])
    when :not_found
      I18n.t("users.messages.rpii_not_found")
    else
      I18n.t("users.messages.rpii_verification_failed")
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    if current_user&.admin?
      admin_permitted_params = %i[
        active_until email inspection_company_id name password
        password_confirmation rpii_inspector_number
      ]
      params.require(:user).permit(admin_permitted_params)
    elsif action_name == "create"
      # Allow name and RPII number during user registration
      params.require(:user).permit(:email, :name, :rpii_inspector_number, :password, :password_confirmation)
    else
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end

  # Using require_admin from ApplicationController

  def require_correct_user
    unless current_user == @user
      action = action_name.include?("password") ? "password" : "settings"
      flash[:alert] = I18n.t("users.messages.own_action_only", action: action)
      redirect_to root_path
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def settings_params
    settings_fields = %i[
      address country default_inspection_location
      phone postal_code theme time_display
    ]
    params.require(:user).permit(settings_fields)
  end
end
