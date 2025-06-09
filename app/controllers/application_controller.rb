class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include SessionsHelper

  before_action :require_login
  before_action :update_last_active_at

  # Performance tracking for debug info
  before_action :start_debug_timer, if: :admin_debug_enabled?

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

  def start_debug_timer
    @debug_start_time = Time.current
    @debug_sql_queries = []

    # Subscribe to SQL queries for this request
    ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      unless payload[:name] == "SCHEMA" || payload[:sql] =~ /^PRAGMA/
        @debug_sql_queries << {
          sql: payload[:sql],
          duration: ((finish - start) * 1000).round(2),
          name: payload[:name]
        }
      end
    end
  end

  # Make debug data available to views
  helper_method :admin_debug_enabled?, :impersonating?, :debug_render_time, :debug_sql_queries

  def debug_render_time
    # Calculate time since request started
    if @debug_start_time
      ((Time.current - @debug_start_time) * 1000).round(2)
    end
  end

  def debug_sql_queries
    @debug_sql_queries || []
  end
end
