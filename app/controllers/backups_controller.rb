# frozen_string_literal: true

class BackupsController < ApplicationController
  before_action :require_admin_user
  before_action :ensure_s3_enabled

  def index
    @backups = fetch_backups
  end

  def download
    backup_key = params[:key]
    unless backup_key.present? && backup_key.start_with?("db_backups/")
      flash[:error] = t("backups.errors.invalid_backup")
      redirect_to backups_path and return
    end

    service = get_s3_service
    presigned_url = service.url(
      backup_key,
      expires_in: 300, # 5 minutes
      response_content_disposition: "attachment; filename=\"#{File.basename(backup_key)}\""
    )

    redirect_to presigned_url, allow_other_host: true
  rescue => e
    Rails.logger.error "Failed to generate download URL: #{e.message}"
    flash[:error] = t("backups.errors.download_failed")
    redirect_to backups_path
  end

  private

  def require_admin_user
    unless current_user&.admin?
      flash[:error] = t("errors.unauthorized")
      redirect_to root_path
    end
  end

  def ensure_s3_enabled
    unless ENV["USE_S3_STORAGE"] == "true"
      flash[:error] = t("backups.errors.s3_not_enabled")
      redirect_to admin_path
    end
  end

  def get_s3_service
    service = ActiveStorage::Blob.service
    unless service.class.name == "ActiveStorage::Service::S3Service" # standard:disable Style/ClassEqualityComparison
      raise "Active Storage is not configured to use S3"
    end
    service
  end

  def fetch_backups
    service = get_s3_service
    bucket = service.send(:bucket)

    backups = []
    bucket.objects(prefix: "db_backups/").each do |object|
      next unless object.key.match?(/database-\d{4}-\d{2}-\d{2}\.tar\.gz$/)

      backups << {
        key: object.key,
        filename: File.basename(object.key),
        size: object.size,
        last_modified: object.last_modified,
        size_mb: (object.size / 1024.0 / 1024.0).round(2)
      }
    end

    backups.sort_by { |b| b[:last_modified] }.reverse
  rescue => e
    Rails.logger.error "Failed to fetch backups: #{e.message}"
    flash.now[:error] = t("backups.errors.fetch_failed")
    []
  end
end
