# frozen_string_literal: true

class BackupsController < ApplicationController
  before_action :require_admin
  before_action :ensure_s3_enabled

  def index
    @backups = fetch_backups
  end

  def download
    date = params[:date]

    return redirect_with_error("invalid_date") unless valid_date?(date)

    backup_key = build_backup_key(date)
    unless backup_exists?(backup_key)
      return redirect_with_error("backup_not_found")
    end

    presigned_url = generate_download_url(backup_key)
    redirect_to presigned_url, allow_other_host: true
  end

  private

  def ensure_s3_enabled
    return if Rails.configuration.use_s3_storage

    flash[:error] = t("backups.errors.s3_not_enabled")
    redirect_to admin_path
  end

  def get_s3_service
    service = ActiveStorage::Blob.service

    # Only check S3Service class if it's loaded (production/S3 environments)
    if defined?(ActiveStorage::Service::S3Service)
      unless service.is_a?(ActiveStorage::Service::S3Service)
        raise t("backups.errors.s3_not_configured")
      end
    end

    service
  end

  def fetch_backups
    service = get_s3_service
    bucket = service.send(:bucket)

    backups = build_backup_list(bucket)
    backups.sort_by { |b| b[:last_modified] }.reverse
  end

  def backup_exists?(key)
    fetch_backups.any? { |backup| backup[:key] == key }
  end

  def redirect_with_error(error_key)
    flash[:error] = t("backups.errors.#{error_key}")
    redirect_to backups_path
  end

  def generate_download_url(backup_key)
    service = get_s3_service
    bucket = service.send(:bucket)
    object = bucket.object(backup_key)

    filename = File.basename(backup_key)
    disposition = build_content_disposition(filename)

    object.presigned_url(
      :get,
      expires_in: 300,
      response_content_disposition: disposition
    )
  end

  def build_backup_list(bucket)
    backups = []
    bucket.objects(prefix: "db_backups/").each do |object|
      next unless valid_backup_filename?(object.key)

      backups << build_backup_info(object)
    end
    backups
  end

  def valid_backup_filename?(key)
    key.match?(/database-\d{4}-\d{2}-\d{2}\.tar\.gz$/)
  end

  def build_backup_info(object)
    {
      key: object.key,
      filename: File.basename(object.key),
      size: object.size,
      last_modified: object.last_modified,
      size_mb: calculate_size_in_mb(object.size)
    }
  end

  def calculate_size_in_mb(size_bytes)
    (size_bytes / 1024.0 / 1024.0).round(2)
  end

  def build_content_disposition(filename)
    "attachment; filename=\"#{filename}\""
  end

  def valid_date?(date)
    return false unless date.is_a?(String) && date.present?

    date.match?(/\A\d{4}-\d{2}-\d{2}\z/) && Date.parse(date)
  rescue Date::Error
    false
  end

  def build_backup_key(date)
    "db_backups/database-#{date}.tar.gz"
  end
end
