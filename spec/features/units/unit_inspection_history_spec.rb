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

    it "displays inspector name from user" do
      inspection

      visit unit_path(unit)

      expect(page).to have_content(I18n.t("inspections.fields.inspector"))
      expect(page).to have_content(user.name)
    end

    it "displays different inspector names for different users" do
      inspection
      other_user = create(:user, name: "Jane Inspector")
      create(
        :inspection,
        user: other_user,
        unit: unit,
        inspection_date: 2.weeks.ago
      )

      visit unit_path(unit)

      expect(page).to have_content(user.name)
      expect(page).to have_content(other_user.name)
    end
  end
end
