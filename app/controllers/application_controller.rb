class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include SessionsHelper

  before_action :require_login
  before_action :update_last_active_at

  # Performance tracking for debug info
  around_action :track_performance, if: :admin_debug_enabled?

  private

  def require_login
    unless logged_in?
      flash[:alert] = I18n.t("authorization.login_required")
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
      flash[:alert] = I18n.t("authorization.admin_required")
      redirect_to root_path
    end
  end

  def admin_debug_enabled?
    Rails.env.development? || current_user&.admin? || impersonating?
  end

  def impersonating?
    # Check if we have an original admin ID stored (indicating impersonation is active)
    session[:original_admin_id].present?
  end

  def track_performance
    @debug_start_time = Time.current
    @debug_sql_queries = []

    # Subscribe to SQL queries
    sql_subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      unless payload[:name] == "SCHEMA" || payload[:sql] =~ /^PRAGMA/
        @debug_sql_queries << {
          sql: payload[:sql],
          duration: ((finish - start) * 1000).round(2),
          name: payload[:name]
        }
      end
    end

    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(sql_subscription) if sql_subscription
    @debug_render_time = ((Time.current - @debug_start_time) * 1000).round(2) if @debug_start_time
  end

  # Make debug data available to views
  helper_method :admin_debug_enabled?, :impersonating?
end
