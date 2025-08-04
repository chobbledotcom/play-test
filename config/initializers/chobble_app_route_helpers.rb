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
    
    def chobble_app_page_path(page, options = {})
      page_path(page, options)
    end
    
    def chobble_app_pages_path(options = {})
      pages_path(options)
    end
    
    def chobble_app_user_url(user, options = {})
      user_url(user, options)
    end
    
    def chobble_app_users_url(options = {})
      users_url(options)
    end
    
    def chobble_app_page_url(page, options = {})
      page_url(page, options)
    end
    
    def chobble_app_pages_url(options = {})
      pages_url(options)
    end
  end
  
  # Also add to controllers
  ActionController::Base.class_eval do
    helper_method :chobble_app_user_path, :chobble_app_users_path, :chobble_app_page_path, :chobble_app_pages_path,
                  :chobble_app_user_url, :chobble_app_users_url, :chobble_app_page_url, :chobble_app_pages_url
    
    def chobble_app_user_path(user, options = {})
      user_path(user, options)
    end
    
    def chobble_app_users_path(options = {})
      users_path(options)
    end
    
    def chobble_app_page_path(page, options = {})
      page_path(page, options)
    end
    
    def chobble_app_pages_path(options = {})
      pages_path(options)
    end
    
    def chobble_app_user_url(user, options = {})
      user_url(user, options)
    end
    
    def chobble_app_users_url(options = {})
      users_url(options)
    end
    
    def chobble_app_page_url(page, options = {})
      page_url(page, options)
    end
    
    def chobble_app_pages_url(options = {})
      pages_url(options)
    end
  end
end