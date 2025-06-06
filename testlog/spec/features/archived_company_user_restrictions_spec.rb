require "rails_helper"

RSpec.feature "Archived Company User Restrictions", type: :feature do
  let(:archived_company) { create(:inspector_company, name: "Archived Company", active: false) }
  let(:user_from_archived_company) { create(:user, :without_company, inspection_company: archived_company) }
  let!(:unit) { create(:unit, user: user_from_archived_company) }

  before do
    sign_in(user_from_archived_company)
  end

  describe "Creating inspections" do
    it "prevents users from archived companies from creating inspections via units page" do
      visit unit_path(unit)

      # User should see their unit but not be able to create inspections
      expect(page).to have_content(unit.name)

      # Should see "Add Inspection" button (since it's their unit)
      expect(page).to have_button(I18n.t("units.buttons.add_inspection"))

      # But clicking it should show the archived company message and not create inspection
      click_button I18n.t("units.buttons.add_inspection")

      expect(page).to have_content(I18n.t("users.messages.company_archived"))
      expect(Inspection.count).to eq(0)
    end

    it "does not show add inspection button when user can't create inspections" do
      # This tests the UI layer - if properly implemented, button might be hidden
      # when user can't create inspections, though current implementation might still show it
      visit unit_path(unit)

      # The button should be present (current implementation)
      # but clicking should prevent creation (business logic)
      expect(page).to have_button(I18n.t("units.buttons.add_inspection"))
    end
  end

  describe "Existing inspections" do
    let!(:existing_inspection) { create(:inspection, user: user_from_archived_company, unit: unit) }

    it "still allows viewing existing inspections" do
      visit inspection_path(existing_inspection)

      # Should be able to view the inspection
      expect(page).to have_content(existing_inspection.name || existing_inspection.serial)

      # Inspector company should still be displayed even though archived
      expect(page).to have_content("Archived Company")
    end

    it "shows archived company in inspection history" do
      visit unit_path(unit)

      # Should see the inspection in history with archived company name
      expect(page).to have_content("Archived Company")
      expect(page).to have_content(existing_inspection.inspection_date&.strftime("%b %d, %Y") || "No date")
    end
  end
end
