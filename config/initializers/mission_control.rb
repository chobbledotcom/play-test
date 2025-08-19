# typed: false
# frozen_string_literal: true

# Only configure Mission Control if it's available (development/production environments)
# Mission Control is not included in test environment to avoid loading issues with Tapioca
if defined?(MissionControl::Jobs)
  MissionControl::Jobs.base_controller_class = "::ApplicationController"
  MissionControl::Jobs.http_basic_auth_enabled = false

  Rails.application.config.to_prepare do
    MissionControl::Jobs::ApplicationController.class_eval do
      skip_before_action :authenticate_by_http_basic, raise: false
      before_action :require_admin
    end
  end
end
