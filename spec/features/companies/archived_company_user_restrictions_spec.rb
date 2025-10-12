# typed: false

require "rails_helper"

RSpec.feature "Inactive User Restrictions", type: :feature do
  let(:archived_company) { create(:inspector_company, name: "Archived Company", active: false) }
  let(:inactive_user) { create(:user, :inactive_user, inspection_company: archived_company) }
  let!(:unit) { create(:unit, user: inactive_user) }

  before do
    sign_in(inactive_user)
  end

  describe "creating inspections" do
    scenario "prevents inactive users from creating inspections" do
      visit unit_path(unit)

      expect(page).to have_content(unit.name)
      expect(page).to have_button(I18n.t("units.buttons.add_inspection"))

      click_button I18n.t("units.buttons.add_inspection")

      expect(page).to have_content(I18n.t("users.messages.user_inactive"))
      expect(inactive_user.inspections.count).to eq(0)
      expect(current_path).to eq(unit_path(unit))
    end
  end

  describe "existing inspections" do
    let(:existing_inspection) { create(:inspection, user: inactive_user, unit: unit) }

    scenario "allows viewing existing inspections" do
      existing_inspection
      visit inspection_path(existing_inspection)

      expect(page).to have_content(unit.name)
      expect(page).to have_content(I18n.t("users.messages.user_inactive"))
    end

    scenario "shows inspector name in inspection history" do
      existing_inspection
      visit unit_path(unit)

      expect(page).to have_content(inactive_user.name)
      formatted_date = existing_inspection.inspection_date&.strftime("%b %d, %Y") || "No date"
      expect(page).to have_content(formatted_date)
    end
  end
end
