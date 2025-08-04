# frozen_string_literal: true

class ApplicationController < ChobbleApp::ApplicationController
  include ImageProcessable
  
  # Route helpers for ChobbleApp models to map to regular routes
  helper_method :chobble_app_user_path, :chobble_app_users_path
  
  def chobble_app_user_path(user, options = {})
    user_path(user, options)
  end
  
  def chobble_app_users_path(options = {})
    users_path(options)
  end

  # App-specific customizations can go here
end
