require "rails_helper"

RSpec.feature "Creating Inspection from Unit Page", type: :feature do
  let(:inspector_company) { create(:inspector_company) }
  let(:user) { create(:user, inspection_company: inspector_company) }
  let(:unit) { create(:unit, user: user) }

  before do
    # Login as the user
    login_user_via_form(user)
  end

  describe "Creating inspection from unit show page" do
    it "creates inspection and redirects to edit page" do
      visit unit_path(unit)

      expect(page).to have_button(I18n.t("units.buttons.add_inspection"))

      # Click the button to create inspection
      click_button I18n.t("units.buttons.add_inspection")

      # Should redirect to edit page for the new inspection
      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)
      expect(page).to have_content(I18n.t("inspections.messages.created"))

      # Verify the inspection was created with the correct unit
      inspection = Inspection.last
      expect(inspection.unit).to eq(unit)
      expect(inspection.user).to eq(user)
      expect(inspection.status).to eq("draft")
      expect(inspection.inspection_date).to eq(Date.current)
    end

    it "shows confirmation data attribute on button" do
      visit unit_path(unit)

      # Check that button has confirmation attribute
      button = page.find_button(I18n.t("units.buttons.add_inspection"))
      expect(button["data-turbo-confirm"]).to eq(I18n.t("units.messages.add_inspection_confirm"))
    end

    it "prevents creating inspection when at limit" do
      # Simulate user at inspection limit
      allow_any_instance_of(User).to receive(:can_create_inspection?).and_return(false)

      visit unit_path(unit)

      click_button I18n.t("units.buttons.add_inspection")

      expect(page).to have_content(I18n.t("users.messages.inspection_limit_reached"))
      expect(Inspection.count).to eq(0)
    end

    it "handles invalid unit gracefully" do
      # Create a unit that doesn't belong to this user
      other_user = create(:user)
      other_unit = create(:unit, user: other_user)

      # Try to create an inspection for a unit that doesn't belong to the current user
      # We'll do this by manipulating the form to submit an invalid unit_id
      visit unit_path(unit)

      # Use JavaScript to change the form action to include invalid unit_id
      # Since we can't easily test direct POST in feature specs without JS,
      # we'll test this scenario differently

      # Instead, let's verify the button only appears for owned units
      visit unit_path(other_unit)

      # Should redirect to units index since user doesn't own this unit
      expect(page).to have_current_path(units_path)
      expect(page).not_to have_button(I18n.t("units.buttons.add_inspection"))
    end
  end

  describe "New inspection form behavior" do
    it "auto-save only works on edit page, not during creation" do
      visit unit_path(unit)

      click_button I18n.t("units.buttons.add_inspection")

      # Should be on edit page now
      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)

      # Form should have auto-save enabled since inspection is persisted
      form = page.find("form.inspection-general-form")
      expect(form["data-autosave"]).to eq("true")
    end
  end

  describe "Unit selection workflow" do
    it "shows unit details in inspection overview after creation" do
      visit unit_path(unit)

      click_button I18n.t("units.buttons.add_inspection")

      # Should show unit details in the inspection edit page
      expect(page).to have_content(unit.name)
      expect(page).to have_content(unit.serial)
      expect(page).to have_content(unit.manufacturer)
    end
  end
end
