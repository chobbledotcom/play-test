# frozen_string_literal: true

# Add route helpers for ChobbleApp namespaced models
# The forms use the model's class name to generate route helpers
# Since User inherits from ChobbleApp::User, forms try to use chobble_app_user_path

Rails.application.config.after_initialize do
  ActionView::Base.class_eval do
    def chobble_app_user_path(user, options = {})
      user_path(user, options)
    end
    
    def chobble_app_users_path(options = {})
      users_path(options)
    end
  end
  
  # Also add to controllers
  ActionController::Base.class_eval do
    helper_method :chobble_app_user_path, :chobble_app_users_path
    
    def chobble_app_user_path(user, options = {})
      user_path(user, options)
    end
    
    def chobble_app_users_path(options = {})
      users_path(options)
    end
  end
end