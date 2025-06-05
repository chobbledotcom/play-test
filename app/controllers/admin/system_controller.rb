# RPII Utility - Admin controller for system management
class Admin::SystemController < ApplicationController
  before_action :authenticate_admin!

  # System health and monitoring
  def dashboard
    @system_stats = SystemStatistics.current
    @recent_errors = ErrorLog.recent.limit(10)
    @database_health = DatabaseHealth.check
  end

  def backup_database
    BackupJob.perform_later
    redirect_to admin_system_dashboard_path, notice: 'Database backup initiated.'
  end

  def error_logs
    @error_logs = ErrorLog.recent.page(params[:page])
  end

  def system_info
    @rails_version = Rails.version
    @ruby_version = RUBY_VERSION
    @database_version = ActiveRecord::Base.connection.select_value("SELECT version()")
    @uptime = Time.current - Rails.application.config.booted_at
  end
end