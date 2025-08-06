# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_before_action :require_login

  def not_found
    render status: :not_found
  end
end