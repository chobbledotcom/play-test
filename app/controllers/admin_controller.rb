# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_admin_user

  def index
    @show_backups = ENV["USE_S3_STORAGE"] == "true"
  end

  private

  def require_admin_user
    unless current_user&.admin?
      flash[:error] = t("errors.unauthorized")
      redirect_to root_path
    end
  end
end
