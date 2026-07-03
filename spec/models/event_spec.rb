# typed: false

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

require "rails_helper"

RSpec.describe Event, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  describe "validations" do
    it "allows resource_id to be nil for System events" do
      event = Event.new(
        user: user,
        action: "backup_completed",
        resource_type: "System",
        resource_id: nil,
        details: "Daily backup completed"
      )
      expect(event).to be_valid
    end

    it "requires resource_id for non-System events" do
      event = Event.new(
        user: user,
        action: "updated",
        resource_type: "Unit",
        resource_id: nil
      )
      expect(event).not_to be_valid
      expect(event.errors[:resource_id]).to include("can't be blank")
    end
  end

  describe ".log" do
    it "creates an event mapping every attribute from the resource" do
      event = Event.log(
        user: user,
        action: "updated",
        resource: unit,
        details: "Changed the name",
        changed_data: {"name" => "New"},
        metadata: {"ip" => "127.0.0.1"}
      )

      expect(event).to be_persisted
      expect(event.user).to eq(user)
      expect(event.action).to eq("updated")
      expect(event.resource_type).to eq("Unit")
      expect(event.resource_id).to eq(unit.id)
      expect(event.details).to eq("Changed the name")
      expect(event.changed_data).to eq({"name" => "New"})
      expect(event.metadata).to eq({"ip" => "127.0.0.1"})
    end

    it "defaults details, changed_data and metadata to nil" do
      event = Event.log(user: user, action: "viewed", resource: unit)

      expect(event.details).to be_nil
      expect(event.changed_data).to be_nil
      expect(event.metadata).to be_nil
    end
  end

  describe ".log_system_event" do
    it "creates an event with the system resource type and no resource id" do
      event = Event.log_system_event(
        user: user,
        action: "backup_completed",
        details: "Daily backup completed",
        metadata: {"size" => "1GB"}
      )

      expect(event).to be_persisted
      expect(event.user).to eq(user)
      expect(event.action).to eq("backup_completed")
      expect(event.resource_type).to eq(Event.system_resource_type)
      expect(event.resource_id).to be_nil
      expect(event.details).to eq("Daily backup completed")
      expect(event.metadata).to eq({"size" => "1GB"})
    end

    it "defaults metadata to nil when omitted" do
      event = Event.log_system_event(
        user: user,
        action: "backup_completed",
        details: "Daily backup completed"
      )

      expect(event.metadata).to be_nil
    end
  end

  describe "#description" do
    it "returns the details when present" do
      event = Event.log(
        user: user,
        action: "updated",
        resource: unit,
        details: "A human readable summary"
      )

      expect(event.description).to eq("A human readable summary")
    end

    it "falls back to a summary built from the event fields" do
      event = Event.log(user: user, action: "updated", resource: unit)
      expected = "#{user.email} updated Unit #{unit.id}"

      expect(event.description).to eq(expected)
    end
  end

  describe "#triggered_by?" do
    it "is true for the user who triggered the event" do
      event = Event.log(user: user, action: "viewed", resource: unit)

      expect(event.triggered_by?(user)).to be true
    end

    it "is false for a different user" do
      other_user = create(:user)
      event = Event.log(user: user, action: "viewed", resource: unit)

      expect(event.triggered_by?(other_user)).to be false
    end
  end

  describe "#resource_object" do
    it "returns the resource when it still exists" do
      event = Event.log(user: user, action: "viewed", resource: unit)

      expect(event.resource_object).to eq(unit)
    end

    it "returns nil when resource has been deleted" do
      event = Event.create!(
        user: user,
        action: "deleted",
        resource: unit,
        details: "Unit deleted"
      )

      unit.destroy

      expect(event.resource_object).to be_nil
    end

    it "handles invalid resource_type gracefully" do
      event = Event.create!(
        user: user,
        action: "viewed",
        resource_type: "NonExistentModel",
        resource_id: 123
      )

      expect(event.resource_object).to be_nil
    end
  end
end
