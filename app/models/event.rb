# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  action        :string           not null
#  changed_data  :json
#  details       :text
#  metadata      :json
#  resource_type :string           not null
#  created_at    :datetime         not null
#  resource_id   :string(12)
#  user_id       :string(12)       not null
#
# Indexes
#
#  index_events_on_action                         (action)
#  index_events_on_created_at                     (created_at)
#  index_events_on_resource_type_and_resource_id  (resource_type,resource_id)
#  index_events_on_user_id                        (user_id)
#  index_events_on_user_id_and_created_at         (user_id,created_at)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

# typed: true
# frozen_string_literal: true

class Event < ApplicationRecord
  extend T::Sig

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
  sig do
    params(
      user: User,
      action: String,
      resource: ActiveRecord::Base,
      details: T.nilable(String),
      changed_data: T.nilable(T::Hash[String, T.any(String, Integer, T::Boolean, NilClass)]),
      metadata: T.nilable(T::Hash[String, T.any(String, Integer, T::Boolean, NilClass)])
    ).returns(Event)
  end
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
  sig do
    params(
      user: User,
      action: String,
      details: String,
      metadata: T.nilable(T::Hash[String, T.any(String, Integer, T::Boolean, NilClass)])
    ).returns(Event)
  end
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
  sig { returns(String) }
  def description
    details || "#{user.email} #{action} #{resource_type} #{resource_id}"
  end

  # Check if the event was triggered by a specific user
  sig { params(check_user: User).returns(T::Boolean) }
  def triggered_by?(check_user)
    user == check_user
  end

  # Get the resource object if it still exists
  sig { returns(T.nilable(ActiveRecord::Base)) }
  def resource_object
    return nil unless resource_type && resource_id
    resource_type.constantize.find_by(id: resource_id)
  rescue NameError
    nil
  end
end
