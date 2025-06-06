require "rails_helper"

RSpec.describe UnitsHelper, type: :helper do
  let(:user) { create(:user) }

  describe "#manufacturer_options" do
    it "returns empty array when user has no units" do
      expect(helper.manufacturer_options(user)).to eq([])
    end

    it "returns unique manufacturers sorted alphabetically" do
      create(:unit, user: user, manufacturer: "ACME Corp")
      create(:unit, user: user, manufacturer: "Beta Industries")
      create(:unit, user: user, manufacturer: "ACME Corp") # duplicate

      result = helper.manufacturer_options(user)
      expect(result).to eq(["ACME Corp", "Beta Industries"])
    end

    it "excludes blank manufacturers" do
      create(:unit, user: user, manufacturer: "Valid Corp")
      unit2 = create(:unit, user: user, manufacturer: "Another Corp")

      # Manually update database to have blank manufacturer (bypassing validations)
      unit2.update_column(:manufacturer, "")

      result = helper.manufacturer_options(user)
      expect(result).to eq(["Valid Corp"])
    end

    it "only returns manufacturers for the specific user" do
      other_user = create(:user)
      create(:unit, user: user, manufacturer: "User1 Corp")
      create(:unit, user: other_user, manufacturer: "User2 Corp")

      result = helper.manufacturer_options(user)
      expect(result).to eq(["User1 Corp"])
    end
  end

  describe "#owner_options" do
    it "returns empty array when user has no units" do
      expect(helper.owner_options(user)).to eq([])
    end

    it "returns unique owners sorted alphabetically" do
      create(:unit, user: user, owner: "John Smith")
      create(:unit, user: user, owner: "Alice Johnson")
      create(:unit, user: user, owner: "John Smith") # duplicate

      result = helper.owner_options(user)
      expect(result).to eq(["Alice Johnson", "John Smith"])
    end

    it "excludes blank owners" do
      create(:unit, user: user, owner: "Valid Owner")
      unit2 = create(:unit, user: user, owner: "Another Owner")

      # Manually update database to have blank owner (bypassing validations)
      unit2.update_column(:owner, "")

      result = helper.owner_options(user)
      expect(result).to eq(["Valid Owner"])
    end

    it "only returns owners for the specific user" do
      other_user = create(:user)
      create(:unit, user: user, owner: "User1 Owner")
      create(:unit, user: other_user, owner: "User2 Owner")

      result = helper.owner_options(user)
      expect(result).to eq(["User1 Owner"])
    end
  end

  describe "#unit_actions" do
    let(:unit) { create(:unit, user: user) }

    it "returns array of action hashes" do
      actions = helper.unit_actions(unit)
      expect(actions).to be_an(Array)
      expect(actions.length).to eq(4)
    end

    it "includes edit action" do
      actions = helper.unit_actions(unit)
      edit_action = actions.find { |a| a[:label] == "Edit" }

      expect(edit_action).to be_present
      expect(edit_action[:url]).to eq(edit_unit_path(unit))
    end

    it "includes PDF report action" do
      actions = helper.unit_actions(unit)
      pdf_action = actions.find { |a| a[:label] == "PDF Report" }

      expect(pdf_action).to be_present
      expect(pdf_action[:url]).to eq(certificate_unit_path(unit))
      expect(pdf_action[:target]).to eq("_blank")
    end

    it "includes delete action with danger flag" do
      actions = helper.unit_actions(unit)
      delete_action = actions.find { |a| a[:label] == "Delete" }

      expect(delete_action).to be_present
      expect(delete_action[:url]).to eq(unit)
      expect(delete_action[:method]).to eq(:delete)
      expect(delete_action[:danger]).to be true
    end

    it "includes add inspection action" do
      actions = helper.unit_actions(unit)
      inspection_action = actions.find { |a| a[:label] == "Add Inspection" }

      expect(inspection_action).to be_present
      expect(inspection_action[:url]).to eq(new_inspection_path(unit_id: unit.id))
    end
  end
end
