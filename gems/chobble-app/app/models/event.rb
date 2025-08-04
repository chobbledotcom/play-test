module ChobbleApp
  class Event < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  validates :action, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true,
    unless: -> { resource_type == "System" }

  # Scopes for common queries
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_resource, ->(resource) { where(resource: resource) }
  scope :by_action, ->(action) { where(action: action) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :this_week, -> { where(created_at: Date.current.all_week) }

  # Helper to create events easily
  def self.log(user:, action:, resource:, details: nil,
    changed_data: nil, metadata: nil)
    create!(
      user: user,
      action: action,
      resource_type: resource.class.name,
      resource_id: resource.id,
      details: details,
      changed_data: changed_data,
      metadata: metadata
    )
  end

  # Helper for system events that don't have a specific resource
  def self.log_system_event(user:, action:, details:, metadata: nil)
    create!(
      user: user,
      action: action,
      resource_type: "System",
      resource_id: nil,
      details: details,
      metadata: metadata
    )
  end

  # Formatted description for display
  def description
    details || "#{user.email} #{action} #{resource_type} #{resource_id}"
  end

  # Check if the event was triggered by a specific user
  def triggered_by?(check_user)
    user == check_user
  end

  # Get the resource object if it still exists
  def resource_object
    return nil unless resource_type && resource_id
    resource_type.constantize.find_by(id: resource_id)
  rescue NameError
    nil
  end
  end
end
