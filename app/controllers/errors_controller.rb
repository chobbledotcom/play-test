# typed: false
# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :update_last_active_at

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json do
        render json: {error: I18n.t("errors.not_found.title")},
          status: :not_found
      end
      format.any { head :not_found }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json do
        render json: {error: I18n.t("errors.internal_server_error.title")},
          status: :internal_server_error
      end
      format.any { head :internal_server_error }
    end
  end
end
