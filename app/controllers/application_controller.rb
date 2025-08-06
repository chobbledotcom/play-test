# typed: false
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include SessionsHelper
  include ImageProcessable

  before_action :require_login
  before_action :update_last_active_at

  before_action :start_debug_timer, if: :admin_debug_enabled?
  after_action :cleanup_debug_subscription, if: :admin_debug_enabled?

  around_action :n_plus_one_detection unless Rails.env.production?

  rescue_from StandardError do |exception|
    if Rails.env.production? && should_notify_error?(exception)
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
    return if logged_in?

    flash[:alert] = form_i18n(:session_new, "status.login_required")
    redirect_to login_path
  end

  def require_logged_out
    return unless logged_in?

    flash[:alert] = form_i18n(:session_new, "status.already_logged_in")
    redirect_to inspections_path
  end

  def update_last_active_at
    return unless current_user.is_a?(User)

    current_user.update(last_active_at: Time.current)

    # Update UserSession last_active_at
    if session[:session_token]
      current_session&.touch_last_active
    end
  end

  def require_admin
    return if current_user&.admin?

    flash[:alert] = I18n.t("forms.session_new.status.admin_required")
    redirect_to root_path
  end

  def admin_debug_enabled?
    Rails.env.development?
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

    ActiveSupport::Notifications.unsubscribe(@debug_subscription) if @debug_subscription

    @debug_subscription = ActiveSupport::Notifications
      .subscribe("sql.active_record") do |_name, start, finish, _id, payload|
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
    return unless @debug_start_time

    ((Time.current - @debug_start_time) * 1000).round(2)
  end

  def debug_sql_queries
    @debug_sql_queries || []
  end

  def n_plus_one_detection
    Prosopite.scan
    yield
  ensure
    Prosopite.finish
  end

  def processing_image_upload?
    case controller_name
    when "users"
      action_name == "update_settings" && params.dig(:user, :logo).present?
    when "units"
      %w[create update].include?(action_name) &&
        params.dig(:unit, :photo).present?
    else
      false
    end
  end

  def cleanup_debug_subscription
    return unless @debug_subscription

    ActiveSupport::Notifications.unsubscribe(@debug_subscription)
    @debug_subscription = nil
  end

  def should_notify_error?(exception)
    if exception.is_a?(ActionController::InvalidAuthenticityToken)
      csrf_ignored_actions = [
        %w[sessions create],
        %w[users create]
      ]

      action = [controller_name, action_name]
      return false if csrf_ignored_actions.include?(action)
    end

    true
  end

  def handle_pdf_response(result, filename)
    case result.type
    when :redirect
      Rails.logger.info "PDF response: Redirecting to S3 URL for #{filename}"
      redirect_to result.data, allow_other_host: true
    when :stream
      Rails.logger.info "PDF response: Streaming #{filename} from S3 through Rails"
      expires_in 0, public: false
      send_data result.data.download,
        filename: filename,
        type: "application/pdf",
        disposition: "inline"
    when :pdf_data
      Rails.logger.info "PDF response: Sending generated PDF data for #{filename}"
      send_data result.data,
        filename: filename,
        type: "application/pdf",
        disposition: "inline"
    end
  end

  def not_found
    render file: "#{Rails.root}/app/views/errors/not_found.html.erb",
      layout: true,
      status: :not_found
  end
end
