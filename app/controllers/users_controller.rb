# frozen_string_literal: true

class UsersController < ApplicationController
  include TurboStreamResponders

  NON_ADMIN_PATHS = %i[
    change_settings
    change_password
    update_settings
    update_password
    logout_everywhere_else
  ].freeze

  LOGGED_OUT_PATHS = %i[
    create
    new
  ].freeze

  skip_before_action :require_login, only: LOGGED_OUT_PATHS
  skip_before_action :update_last_active_at, only: [:update_settings]
  before_action :set_user, except: %i[index new create]
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
      NtfyService.notify("new user: #{@user.email}") if Rails.env.production?

      log_in @user
      create_session_record @user
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
    params[:user][:inspection_company_id] = nil if params[:user][:inspection_company_id] == ""

    if @user.update(user_params)
      handle_update_success(@user, "users.messages.user_updated", users_path)
    else
      handle_update_failure(@user)
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
    params_to_update = settings_params

    if @image_processing_error
      flash[:alert] = @image_processing_error.message
      redirect_to change_settings_user_path(@user)
      return
    end

    if @user.update(params_to_update)
      additional_streams = []

      if params[:user][:logo].present?
        additional_streams << turbo_stream.replace(
          "user_logo_field",
          partial: "chobble_forms/file_field_turbo_response",
          locals: {
            model: @user,
            field: :logo,
            turbo_frame_id: "user_logo_field",
            i18n_base: "forms.user_settings",
            accept: "image/*"
          }
        )
      end

      if params[:user][:signature].present?
        additional_streams << turbo_stream.replace(
          "user_signature_field",
          partial: "chobble_forms/file_field_turbo_response",
          locals: {
            model: @user,
            field: :signature,
            turbo_frame_id: "user_signature_field",
            i18n_base: "forms.user_settings",
            accept: "image/*"
          }
        )
      end

      handle_update_success(
        @user,
        "users.messages.settings_updated",
        change_settings_user_path(@user),
        additional_streams: additional_streams
      )
    else
      handle_update_failure(@user, :change_settings)
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

  def activate
    @user.update(active_until: 1000.years.from_now)
    flash[:notice] = I18n.t("users.messages.user_activated")
    redirect_to edit_user_path(@user)
  end

  def deactivate
    @user.update(active_until: Time.current)
    flash[:notice] = I18n.t("users.messages.user_deactivated")
    redirect_to edit_user_path(@user)
  end

  def logout_everywhere_else
    # Delete all sessions except the current one
    current_token = session[:session_token]
    @user.user_sessions.where.not(session_token: current_token).destroy_all
    flash[:notice] = I18n.t("users.messages.logged_out_everywhere")
    redirect_to change_settings_user_path(@user)
  end

  private

  def create_session_record(user)
    user.user_sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      last_active_at: Time.current
    )
  end

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
    return if current_user == @user

    action = action_name.include?("password") ? "password" : "settings"
    flash[:alert] = I18n.t("users.messages.own_action_only", action: action)
    redirect_to root_path
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def settings_params
    settings_fields = %i[
      address country
      logo phone postal_code signature theme
    ]
    permitted_params = params.require(:user).permit(settings_fields)

    process_image_params(permitted_params, :logo, :signature)
  end
end
