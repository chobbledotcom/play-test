class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include SessionsHelper

  before_action :require_login
  before_action :update_last_active_at

  private

  def require_login
    unless logged_in?
      flash[:danger] = I18n.t("authorization.login_required")
      redirect_to login_path
    end
  end

  def update_last_active_at
    if current_user&.is_a?(User)
      current_user.update(last_active_at: Time.current)
    end
  end

  def require_admin
    unless current_user&.admin?
      flash[:danger] = I18n.t("authorization.admin_required")
      redirect_to root_path
    end
  end
end
