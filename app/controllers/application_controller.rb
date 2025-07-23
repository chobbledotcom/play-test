class ApplicationController < ActionController::Base
  include SessionsHelper

  before_action :require_login
  before_action :update_last_active_at

  # Performance tracking for debug info
  before_action :start_debug_timer, if: :admin_debug_enabled?
  after_action :check_query_limit, if: :should_check_query_limit?
  after_action :cleanup_debug_subscription, if: :admin_debug_enabled?

  rescue_from StandardError do |exception|
    if Rails.env.production?
      user_email = current_user&.email || app_i18n(:errors, :not_logged_in)
      user_label = app_i18n(:errors, :user_label)
      user_info = "#{user_label}: #{user_email}"

      controller_label = app_i18n(:errors, :controller_label)
      path_label = app_i18n(:errors, :path_label)
      method_label = app_i18n(:errors, :method_label)
      ip_label = app_i18n(:errors, :ip_label)
      backtrace_label = app_i18n(:errors, :backtrace_label)
      error_subject = app_i18n(:errors, :production_error_subject)

      message = <<~MESSAGE
        #{error_subject}

        #{exception.class}: #{exception.message}

        #{user_info}
        #{controller_label}: #{controller_name}##{action_name}
        #{path_label}: #{request.fullpath}
        #{method_label}: #{request.request_method}
        #{ip_label}: #{request.remote_ip}

        #{backtrace_label}:
        #{exception.backtrace.first(5).join("\n")}
      MESSAGE

      NtfyService.notify(message)
    end

    raise exception
  end

  private

  def app_i18n(table, key, **args)
    I18n.t("application.#{table}.#{key}", **args)
  end

  def form_i18n(form, key, **args)
    I18n.t("forms.#{form}.#{key}", **args)
  end

  def require_login
    unless logged_in?
      flash[:alert] = form_i18n(:session_new, "status.login_required")
      redirect_to login_path
    end
  end

  def require_logged_out
    if logged_in?
      flash[:alert] = form_i18n(:session_new, "status.already_logged_in")
      redirect_to inspections_path
    end
  end

  def update_last_active_at
    if current_user&.is_a?(User)
      current_user.update(last_active_at: Time.current)
    end
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = I18n.t("forms.session_new.status.admin_required")
      redirect_to root_path
    end
  end

  def admin_debug_enabled?
    Rails.env.development? || current_user&.admin? || impersonating?
  end

  def should_check_query_limit?
    admin_debug_enabled? && !seed_data_action?
  end

  def seed_data_action?
    seed_actions = %w[add_seeds delete_seeds]
    controller_name == "users" && seed_actions.include?(action_name)
  end

  def impersonating?
    session[:original_admin_id].present?
  end

  def start_debug_timer
    @debug_start_time = Time.current
    @debug_sql_queries = []

    if @debug_subscription
      ActiveSupport::Notifications.unsubscribe(@debug_subscription)
    end

    @debug_subscription = ActiveSupport::Notifications
      .subscribe("sql.active_record") do |name, start, finish, id, payload|
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
  helper_method :admin_debug_enabled?,
    :impersonating?,
    :debug_render_time,
    :debug_sql_queries

  def debug_render_time
    if @debug_start_time
      ((Time.current - @debug_start_time) * 1000).round(2)
    end
  end

  def debug_sql_queries
    @debug_sql_queries || []
  end

  def check_query_limit
    table_query_counts = count_queries_by_table

    table_query_counts.each do |table, count|
      if count > 5
        log_n_plus_one_queries(table, count)
        # Only raise exception in development and test environments
        # Skip if we're processing images (which legitimately needs multiple blob queries)
        # Only check N+1 queries on GET requests
        if Rails.env.local? && !processing_image_upload? && request.get?
          message = app_i18n(:debug, :n_plus_one_with_limit, table: table, count: count, limit: 5)
          raise message
        end
      end
    end
  end

  def processing_image_upload?
    case controller_name
    when "users"
      action_name == "update_settings" && params.dig(:user, :logo).present?
    when "units"
      %w[create update].include?(action_name) && params.dig(:unit, :photo).present?
    else
      false
    end
  end

  def log_n_plus_one_queries(table, count)
    error_message = app_i18n(:debug, :n_plus_one_detected, table: table, count: count)
    Rails.logger.error error_message
    Rails.logger.error app_i18n(:debug, :queries_for_table, table: table)
    table_queries = debug_sql_queries.select { |q|
      table_from_query(q[:sql]) == table
    }
    table_queries.each_with_index do |query, i|
      query_log = app_i18n(:debug, :query_log_entry, name: query[:name], sql: query[:sql])
      Rails.logger.error "  #{i + 1}. #{query_log}"
    end
  end

  def count_queries_by_table
    debug_sql_queries.each_with_object(Hash.new(0)) do |query, counts|
      table = table_from_query(query[:sql])
      counts[table] += 1 if table
    end
  end

  def table_from_query(sql)
    if sql =~ /FROM\s+["']?(\w+)["']?/i
      $1
    elsif sql =~ /INSERT\s+INTO\s+["']?(\w+)["']?/i
      $1
    elsif sql =~ /UPDATE\s+["']?(\w+)["']?/i
      $1
    elsif sql =~ /DELETE\s+FROM\s+["']?(\w+)["']?/i
      $1
    end
  end

  def cleanup_debug_subscription
    return unless @debug_subscription

    ActiveSupport::Notifications.unsubscribe(@debug_subscription)
    @debug_subscription = nil
  end
end
