# frozen_string_literal: true

# Configure Mission Control to use our ApplicationController
MissionControl::Jobs.base_controller_class = "::ApplicationController"

# Configure Mission Control to use our session-based authentication
Rails.application.config.to_prepare do
  # Remove HTTP Basic auth and add session-based auth
  MissionControl::Jobs::ApplicationController.class_eval do
    # Skip the default HTTP basic authentication
    skip_before_action :authenticate_by_http_basic, raise: false
    
    # Add our admin authentication
    before_action :require_admin
  end
end