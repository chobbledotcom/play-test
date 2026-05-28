# typed: false
# frozen_string_literal: true

module EventLogging
  extend ActiveSupport::Concern

  private

  def log_event(action, resource, resource_type:, details: nil,
    changed_data: nil)
    return unless current_user

    if resource
      log_resource_event(action, resource, details, changed_data)
    else
      log_system_event(action, details, resource_type)
    end
  rescue => e
    Rails.logger.error I18n.t(
      "events.errors.log_failed",
      resource_type: resource_type,
      message: e.message
    )
  end

  def log_resource_event(action, resource, details = nil, changed_data = nil)
    return unless current_user

    Event.log(
      user: current_user,
      action: action,
      resource: resource,
      details: details,
      changed_data: changed_data
    )
  rescue => e
    Rails.logger.error I18n.t(
      "events.errors.log_failed",
      resource_type: resource.class.name,
      message: e.message
    )
  end

  def log_system_event(action, details, resource_type)
    return unless current_user

    Event.log_system_event(
      user: current_user,
      action: action,
      details: details,
      metadata: {resource_type: resource_type}
    )
  rescue => e
    Rails.logger.error I18n.t(
      "events.errors.system_log_failed",
      message: e.message
    )
  end
end
