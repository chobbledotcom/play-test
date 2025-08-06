# typed: false
# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :update_last_active_at

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
