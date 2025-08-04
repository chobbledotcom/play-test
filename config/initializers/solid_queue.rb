# frozen_string_literal: true

# Disable default HTTP basic auth for Mission Control Jobs
# We're using our own admin authentication instead
Rails.application.config.mission_control.jobs.http_basic_auth_enabled = false

# Set custom base controller for Mission Control authentication
MissionControl::Jobs.base_controller_class = "ApplicationController"