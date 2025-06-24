require "rails_helper"

RSpec.feature "Unit Deletion Restrictions", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    sign_in(user)
  end

  context "when unit has no inspections" do
    it "shows delete button on unit show page" do
      visit unit_path(unit)
      expect(page).to have_button(I18n.t("units.buttons.delete"))
    end

    it "shows delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).to have_button(I18n.t("units.buttons.delete"))
    end

    it "successfully deletes unit via direct form submission and preserves audit log" do
      visit unit_path(unit)

      # Capture unit details before deletion
      unit_id = unit.id
      unit_name = unit.name
      unit_serial = unit.serial

      # Delete the unit using direct form submission
      page.driver.submit :delete, unit_path(unit), {}

      expect(page).to have_current_path(units_path)
      expect(page).to have_content(I18n.t("units.messages.deleted"))

      # Unit should be gone
      expect(Unit.find_by(id: unit_id)).to be_nil

      # But audit log should be preserved
      event = Event.where(resource_type: "Unit", resource_id: unit_id, action: "deleted").first
      expect(event).to be_present
      expect(event.metadata["name"]).to eq(unit_name)
      expect(event.metadata["serial"]).to eq(unit_serial)
    end

    it "successfully deletes unit via UI with JavaScript", js: true do
      visit unit_path(unit)

      # Capture unit details before deletion
      unit_id = unit.id
      unit_name = unit.name
      unit_serial = unit.serial

      # Delete the unit with confirm dialog
      accept_confirm do
        click_button I18n.t("units.buttons.delete")
      end

      expect(page).to have_current_path(units_path)
      expect(page).to have_content(I18n.t("units.messages.deleted"))

      # Unit should be gone
      expect(Unit.find_by(id: unit_id)).to be_nil

      # But audit log should be preserved
      event = Event.where(resource_type: "Unit", resource_id: unit_id, action: "deleted").first
      expect(event).to be_present
      expect(event.metadata["name"]).to eq(unit_name)
      expect(event.metadata["serial"]).to eq(unit_serial)
    end
  end

  context "when unit has only draft inspections" do
    before do
      create(:inspection, unit: unit, user: user, complete_date: nil)
    end

    it "shows delete button on unit show page" do
      visit unit_path(unit)
      expect(page).to have_button(I18n.t("units.buttons.delete"))
    end

    it "shows delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).to have_button(I18n.t("units.buttons.delete"))
    end
  end

  context "when unit has completed inspections" do
    before do
      create(:inspection, unit: unit, user: user, complete_date: Time.current)
    end

    it "hides delete button on unit show page" do
      visit unit_path(unit)
      expect(page).not_to have_button(I18n.t("units.buttons.delete"))
    end

    it "hides delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).not_to have_button(I18n.t("units.buttons.delete"))
    end
  end

  context "when unit has both draft and completed inspections" do
    before do
      create(:inspection, unit: unit, user: user, complete_date: nil)
      create(:inspection, unit: unit, user: user, complete_date: Time.current)
    end

    it "hides delete button on unit show page" do
      visit unit_path(unit)
      expect(page).not_to have_button(I18n.t("units.buttons.delete"))
    end

    it "hides delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).not_to have_button(I18n.t("units.buttons.delete"))
    end
  end
end
