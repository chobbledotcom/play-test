require "rails_helper"

RSpec.describe ChobbleApp::Event, type: :model do
  let(:user) { create(:user) }
  let(:resource) { create(:page) } # Use Page as a generic resource for testing

  describe "validations" do
    it "allows resource_id to be nil for System events" do
      event = ChobbleApp::Event.new(
        user: user,
        action: "backup_completed",
        resource_type: "System",
        resource_id: nil,
        details: "Daily backup completed"
      )
      expect(event).to be_valid
    end

    it "requires resource_id for non-System events" do
      event = ChobbleApp::Event.new(
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
      event = ChobbleApp::Event.create!(
        user: user,
        action: "deleted",
        resource: resource,
        details: "Resource deleted"
      )

      resource.destroy

      expect(event.resource_object).to be_nil
    end

    it "handles invalid resource_type gracefully" do
      event = ChobbleApp::Event.create!(
        user: user,
        action: "viewed",
        resource_type: "NonExistentModel",
        resource_id: 123
      )

      expect(event.resource_object).to be_nil
    end
  end
end
