# frozen_string_literal: true

class BackupsController < ApplicationController
  before_action :require_admin
  before_action :ensure_s3_enabled

  def index
    @backups = fetch_backups
  end

  def download
    # Parse and validate date parameter
    begin
      backup_date = Date.parse(params[:date])
    rescue ArgumentError, TypeError
      flash[:error] = t("backups.errors.invalid_date")
      redirect_to backups_path and return
    end

    # Construct the backup key from the date
    backup_filename = "database-#{backup_date.strftime("%Y-%m-%d")}.tar.gz"
    backup_key = "db_backups/#{backup_filename}"

    # Verify the backup actually exists
    unless backup_exists?(backup_key)
      flash[:error] = t("backups.errors.backup_not_found")
      redirect_to backups_path and return
    end

    service = get_s3_service
    presigned_url = service.url(
      backup_key,
      expires_in: 300, # 5 minutes
      response_content_disposition: "attachment; filename=\"#{backup_filename}\""
    )

    redirect_to presigned_url, allow_other_host: true
  rescue => e
    Rails.logger.error "Failed to generate download URL: #{e.message}"
    flash[:error] = t("backups.errors.download_failed")
    redirect_to backups_path
  end

  private

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
      match = object.key.match(/database-(\d{4}-\d{2}-\d{2})\.tar\.gz$/)
      next unless match

      backup_date = match[1]
      backups << {
        key: object.key,
        filename: File.basename(object.key),
        date: backup_date,
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

  def backup_exists?(key)
    fetch_backups.any? { |backup| backup[:key] == key }
  rescue
    false
  end
end
