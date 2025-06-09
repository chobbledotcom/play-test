require "rails_helper"

RSpec.describe "Unit Inspection History", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit, inspection_date: 1.week.ago) }

  before do
    sign_in(user)
  end

  describe "viewing unit inspection history" do
    it "displays inspection history table without errors" do
      # Create an inspection to ensure the table has data
      inspection

      visit unit_path(unit)

      # This should reproduce the error: undefined method 'inspector' for Inspection
      expect { page.has_content?("Inspector") }.not_to raise_error

      # The page should display inspection history without crashing
      expect(page).to have_content(I18n.t("inspections.fields.last_inspection"))
      expect(page).to have_content(I18n.t("inspections.fields.inspector"))
      expect(page).to have_content(I18n.t("inspections.fields.result"))
    end

    it "displays inspection with assigned company" do
      # Inspector company should always be assigned
      expect(inspection.inspector_company).to be_present

      visit unit_path(unit)

      expect(page).to have_content(I18n.t("inspections.fields.last_inspection"))
      expect(page).to have_content(I18n.t("inspections.fields.inspector"))
      expect(page).to have_content(inspection.inspector_company.name)
    end

    it "displays inspector company name when present" do
      inspector_company = create(:inspector_company, name: "Test Inspector Co")
      inspection.update!(inspector_company: inspector_company)

      visit unit_path(unit)

      expect(page).to have_content("Test Inspector Co")
    end
  end
end
