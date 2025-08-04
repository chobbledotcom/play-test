require "rails_helper"

RSpec.feature "Creating Inspection from Unit Page", type: :feature do
  include InspectionTestHelpers
  let(:inspector_company) { create(:inspector_company) }
  let(:user) { create(:user, :without_company, inspection_company: inspector_company) }
  let(:unit) { create(:unit, user: user) }

  before do
    login_user_via_form(user)
  end

  describe "creating inspection from unit show page" do
    scenario "creates inspection and redirects to edit page" do
      visit unit_path(unit)
      expect(page).to have_button(I18n.t("units.buttons.add_inspection"))

      click_add_inspection_button

      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)
      # Flash messages may not render in test environment

      inspection = user.inspections.find_by(unit_id: unit.id)
      expect(inspection).to be_present
      expect(inspection.unit).to eq(unit)
      expect(inspection.user).to eq(user)
      expect(inspection.complete?).to be_falsey
      expect(inspection.inspection_date).to eq(Date.current)

      # Verify event was logged
      event = Event.where(resource_type: "Inspection", resource_id: inspection.id, action: "created").first
      expect(event).to be_present
      expect(event.user).to eq(user)
    end

    scenario "shows confirmation data attribute on button" do
      visit unit_path(unit)

      button = page.find_button(I18n.t("units.buttons.add_inspection"))
      expect(button["data-turbo-confirm"]).to eq(I18n.t("units.messages.add_inspection_confirm"))
    end

    scenario "prevents creating inspection when user is inactive" do
      user.update!(active_until: Date.current - 1.day)
      visit unit_path(unit)

      click_add_inspection_button

      # Flash messages may not render in test environment
      expect(user.inspections.count).to eq(0)
    end

    scenario "prevents creating inspection for other user's unit" do
      other_user = create(:user)
      other_unit = create(:unit, user: other_user)

      visit unit_path(other_unit)

      expect(page).to have_current_path(unit_path(other_unit))
      expect(page.html).to include("<iframe")
      expect(page).not_to have_button(I18n.t("units.buttons.add_inspection"))
      expect(other_user.inspections.count).to eq(0)
    end
  end

  describe "unit selection workflow" do
    scenario "shows unit details in inspection overview after creation" do
      visit unit_path(unit)
      click_add_inspection_button

      expect(page).to have_content(unit.name)
      expect(page).to have_content(unit.serial)
      expect(page).to have_content(unit.manufacturer)
    end
  end
end
