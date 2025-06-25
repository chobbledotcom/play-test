class UsersController < ApplicationController
  include UserTurboStreams

  NON_ADMIN_PATHS = %i[
    change_settings
    change_password
    update_settings
    update_password
  ]

  LOGGED_OUT_PATHS = %i[
    create
    new
  ]

  skip_before_action :require_login, only: LOGGED_OUT_PATHS
  skip_before_action :update_last_active_at, only: [:update_settings]
  before_action :set_user, except: %i[ index new create ]
  before_action :require_admin, except: NON_ADMIN_PATHS + LOGGED_OUT_PATHS
  before_action :require_correct_user, only: NON_ADMIN_PATHS

  def index
    @users = User.all
    @inspection_counts = Inspection
      .where(user_id: @users.pluck(:id))
      .group(:user_id)
      .count
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
            turbo_stream.replace("form_save_message",
              partial: "shared/save_message",
              locals: {
                message: I18n.t("users.messages.user_updated")
              })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("form_save_message",
              partial: "shared/save_message",
              locals: {
                errors: @user.errors.full_messages,
                message: t("shared.messages.save_failed")
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
          redirect_to change_settings_user_path(@user)
        end
        format.turbo_stream { render_user_update_success_stream }
      end
    else
      respond_to do |format|
        format.html { render :change_settings, status: :unprocessable_entity }
        format.turbo_stream { render_user_update_error_stream }
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

  def add_seeds
    if @user.has_seed_data?
      flash[:alert] = I18n.t("users.messages.seeds_failed")
    else
      SeedDataService.add_seeds_for_user(@user)
      flash[:notice] = I18n.t("users.messages.seeds_added")
    end
    redirect_to edit_user_path(@user)
  end

  def delete_seeds
    SeedDataService.delete_seeds_for_user(@user)
    flash[:notice] = I18n.t("users.messages.seeds_deleted")
    redirect_to edit_user_path(@user)
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
      params.require(:user).permit(:email, :name, :rpii_inspector_number, :password, :password_confirmation)
    else
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end

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
      logo phone postal_code theme
    ]
    params.require(:user).permit(settings_fields)
  end
end
