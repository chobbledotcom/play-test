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
      user_email = current_user&.email || "Not logged in"
      user_info = "User: #{user_email}"

      message = <<~MESSAGE
        500 Error in play-test

        #{exception.class}: #{exception.message}

        #{user_info}
        Controller: #{controller_name}##{action_name}
        Path: #{request.fullpath}
        Method: #{request.request_method}
        IP: #{request.remote_ip}

        Backtrace (first 5 lines):
        #{exception.backtrace.first(5).join("\n")}
      MESSAGE

      NtfyService.notify(message)
    end

    raise exception
  end

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
        table_msg = "#{table} table was queried #{count} times"
        message = "N+1 query detected: #{table_msg}"
        raise "#{message} (limit: 5)"
      end
    end
  end

  def log_n_plus_one_queries(table, count)
    query_count_msg = "#{table} was queried #{count} times"
    error_message = "N+1 query detected: #{query_count_msg}"
    Rails.logger.error error_message
    Rails.logger.error "Queries for #{table}:"
    table_queries = debug_sql_queries.select { |q|
      table_from_query(q[:sql]) == table
    }
    table_queries.each_with_index do |query, i|
      query_log = "#{query[:name]}: #{query[:sql]}"
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
