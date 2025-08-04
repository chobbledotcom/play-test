# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_admin

  def index
    @show_backups = ENV["USE_S3_STORAGE"] == "true"
  end
end