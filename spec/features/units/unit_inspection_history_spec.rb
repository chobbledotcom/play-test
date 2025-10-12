# typed: false

require "rails_helper"

RSpec.describe "Unit Inspection History", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) do
    date = 1.week.ago
    create(:inspection, user: user, unit: unit, inspection_date: date)
  end

  before do
    sign_in(user)
  end

  describe "viewing unit inspection history" do
    it "displays inspection history table without errors" do
      inspection

      visit unit_path(unit)

      expect { page.has_content?("Inspector") }.not_to raise_error

      expect(page).to have_content(I18n.t("inspections.fields.last_inspection"))
      expect(page).to have_content(I18n.t("inspections.fields.inspector"))
      expect(page).to have_content(I18n.t("inspections.fields.result"))
    end

    it "displays inspection with assigned company" do
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

    context "when inspection has no inspector company" do
      it "displays message when inspector company is missing" do
        date = 1.week.ago
        inspection_no_company = create(
          :inspection,
          user: user,
          unit: unit,
          inspection_date: date
        )
        inspection_no_company.update_column(:inspector_company_id, nil)
        inspection_no_company.reload
        expect(inspection_no_company.inspector_company).to be_nil

        visit unit_path(unit)

        expect(page).to have_content(I18n.t("inspections.fields.inspector"))
        expect(page).to have_content(I18n.t("inspections.messages.no_company"))
      end
    end
  end
end
