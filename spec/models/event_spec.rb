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

  describe "#resource_object" do
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
