require "rails_helper"

RSpec.feature "Inspections Filtering", type: :feature do
  let(:user) { create(:user) }
  let(:unit1) { create(:unit, user: user, name: "Unit A") }
  let(:unit2) { create(:unit, user: user, name: "Unit B") }
  let(:unit3) { create(:unit, user: user, name: "Unit C") }

  let!(:draft_inspection) { create(:inspection, user: user, unit: unit1, complete_date: nil, passed: nil) }
  let!(:completed_passed) { create(:inspection, user: user, unit: unit2, complete_date: Time.current, passed: true) }
  let!(:completed_failed) { create(:inspection, user: user, unit: unit3, complete_date: Time.current, passed: false) }

  before { sign_in(user) }

  describe "status display" do
    before { visit inspections_path }

    it "shows all inspections separated by status" do
      expect(page).to have_content("Unit A")

      expect(page).to have_content("Unit B")
      expect(page).to have_content("Unit C")

      expect(page).to have_content("In Progress")
      expect(page).to have_content("Completed")
    end

    it "does not have status filter (statuses are now separated)" do
      expect(page).not_to have_select("status")
    end
  end

  describe "filtering by result" do
    before { visit inspections_path }

    it "filters by passed result" do
      visit inspections_path(result: "passed")

      within(".inspections-list") do
        expect(page).not_to have_content("Unit A")

        expect(page).to have_content("Unit B")
        expect(page).not_to have_content("Unit C")
      end
    end

    it "filters by failed result" do
      visit inspections_path(result: "failed")

      within(".inspections-list") do
        expect(page).not_to have_content("Unit A")

        expect(page).not_to have_content("Unit B")
        expect(page).to have_content("Unit C")
      end
    end
  end

  describe "filtering by unit" do
    before { visit inspections_path }

    it "filters by specific unit" do
      visit inspections_path(unit_id: unit1.id)

      within(".inspections-list") do
        expect(page).to have_content("Unit A")
        expect(page).not_to have_content("Unit B")
        expect(page).not_to have_content("Unit C")
      end
    end
  end

  describe "combining filters" do
    it "filters by result only (status filtering removed)" do
      visit inspections_path(result: "passed")

      within(".inspections-list") do
        expect(page).not_to have_content("Unit A")

        expect(page).to have_content("Unit B")
        expect(page).not_to have_content("Unit C")
      end
    end

    it "filters by unit and result" do
      visit inspections_path(unit_id: unit3.id, result: "failed")

      within(".inspections-list") do
        expect(page).not_to have_content("Unit A")

        expect(page).not_to have_content("Unit B")
        expect(page).to have_content("Unit C")
      end
    end
  end

  describe "clear filters link" do
    it "shows clear filters link when filters are active" do
      visit inspections_path(result: "passed")

      expect(page).to have_link(I18n.t("ui.buttons.clear_filters"))
    end

    it "clears all filters when clicked" do
      visit inspections_path(result: "passed")
      click_link I18n.t("ui.buttons.clear_filters")

      expect(page).to have_current_path(inspections_path)

      expect(page).to have_content("Unit A")
      expect(page).to have_content("Unit B")
      expect(page).to have_content("Unit C")
    end
  end

  describe "page title updates" do
    it "includes result in title when filtered" do
      visit inspections_path(result: "passed")
      expect(page).to have_content("Inspections - Passed")
    end
  end
end
