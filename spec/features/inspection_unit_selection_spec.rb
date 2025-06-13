require "rails_helper"

RSpec.feature "Inspection Unit Selection", type: :feature do
  let(:user) { create(:user) }
  let!(:unit1) { create(:unit, user: user, name: "Bouncy Castle 1", serial: "BC001", manufacturer: "Acme", owner: "John Doe", description: "Large bouncy castle") }
  let!(:unit2) { create(:unit, user: user, name: "Bouncy Castle 2", serial: "BC002", manufacturer: "Beta Corp") }
  let!(:unit3) { create(:unit, user: user, name: "Slide Unit", serial: "SL001", manufacturer: "Acme") }
  let(:inspection) { create(:inspection, user: user, unit: unit1) }

  before { sign_in(user) }

  describe "changing unit from inspection edit page" do
    before { visit edit_inspection_path(inspection) }

    it "shows current unit details and change unit link" do
      within ".tab-content" do
        expect_unit_details(unit1)
        expect(page).to have_link(I18n.t("inspections.buttons.change_unit"))
        expect(page).to have_link(unit1.name, href: edit_unit_path(unit1))
        expect(page).to have_content("John Doe") # owner
        expect(page).to have_content("Large bouncy castle") # description
      end
    end

    it "navigates to unit selection page when clicking change unit" do
      click_link I18n.t("inspections.buttons.change_unit")

      expect(page).to have_current_path(select_unit_inspection_path(inspection))
      expect(page).to have_content(I18n.t("inspections.titles.select_unit"))
      expect(page).to have_content(I18n.t("inspections.messages.unit_selection_notice"))
    end
  end

  describe "unit selection page" do
    before { visit select_unit_inspection_path(inspection) }

    it "displays all user units in a list with select buttons" do
      expect_units_visible(unit1, unit2, unit3)

      within ".table-list-items" do
        expect(page).to have_button(I18n.t("units.actions.select"), count: 3)
      end
    end

    it "shows unit details in the list" do
      within ".table-list-items" do
        [unit1, unit2, unit3].each do |unit|
          expect(page).to have_content(unit.serial)
          expect(page).to have_content(unit.manufacturer)
        end
      end
    end

    context "filtering" do
      it "filters units by search term" do
        fill_in :search, with: "BC002"
        click_button I18n.t("ui.buttons.search")

        expect_units_visible(unit2)
        expect_units_not_visible(unit1, unit3)
      end

      it "filters units by manufacturer" do
        visit select_unit_inspection_path(inspection, manufacturer: "Acme")

        expect_units_visible(unit1, unit3)
        expect_units_not_visible(unit2)
      end
    end
  end

  describe "selecting a unit" do
    before { visit select_unit_inspection_path(inspection) }

    it "updates the inspection with the selected unit" do
      select_unit_button(unit2)

      expect(page).to have_current_path(edit_inspection_path(inspection))
      expect(page).to have_content(I18n.t("inspections.messages.unit_changed", unit_name: unit2.name))

      within ".tab-content" do
        expect_unit_details(unit2)
      end

      # Verify unit was changed
      inspection.reload
      expect(inspection.unit).to eq(unit2)
    end
  end

  describe "when inspection has no unit" do
    let(:inspection_no_unit) { create(:inspection, user: user, unit: nil) }

    before { visit edit_inspection_path(inspection_no_unit) }

    it "shows select unit link instead of change unit" do
      within ".tab-content" do
        expect(page).to have_content(I18n.t("inspections.messages.no_unit"))
        expect(page).to have_link(I18n.t("inspections.buttons.select_unit"))
        expect(page).not_to have_link(I18n.t("inspections.buttons.change_unit"))
      end
    end

    it "allows selecting a unit" do
      click_link I18n.t("inspections.buttons.select_unit")
      select_unit_button(unit1)

      expect(page).to have_current_path(edit_inspection_path(inspection_no_unit))
      expect(page).to have_content(I18n.t("inspections.messages.unit_changed", unit_name: unit1.name))

      inspection_no_unit.reload
      expect(inspection_no_unit.unit).to eq(unit1)
    end
  end

  describe "security" do
    let(:other_user) { create(:user) }
    let!(:other_unit) { create(:unit, user: other_user, name: "Other Unit") }

    it "only shows units belonging to the current user" do
      visit select_unit_inspection_path(inspection)

      expect_units_visible(unit1, unit2, unit3)
      expect_units_not_visible(other_unit)
    end

    it "prevents selecting units from other users" do
      # Try to directly update with another user's unit ID
      page.driver.submit :patch, update_unit_inspection_path(inspection, unit_id: other_unit.id), {}

      inspection.reload
      expect(inspection.unit).to eq(unit1) # Should not have changed
    end
  end

  describe "complete inspection restrictions" do
    let(:complete_inspection) { create_complete_inspection }

    context "as regular user" do
      it "redirects to show page when trying to access unit selection for complete inspections" do
        visit select_unit_inspection_path(complete_inspection)

        expect(page).to have_current_path(inspection_path(complete_inspection))
        expect(page).to have_content(I18n.t("inspections.messages.cannot_edit_complete"))
      end
    end

    context "as admin" do
      let(:admin_user) { create(:user, :admin) }
      let(:admin_unit) { create(:unit, user: admin_user) }
      let(:admin_complete_inspection) do
        create(:inspection, :with_complete_assessments, user: admin_user, unit: admin_unit).tap do |insp|
          # Mark as complete
          insp.update!(complete_date: Time.current)
        end
      end

      before do
        sign_in(admin_user)
      end

      it "redirects to show page when trying to access unit selection for complete inspections" do
        visit select_unit_inspection_path(admin_complete_inspection)

        expect(page).to have_current_path(inspection_path(admin_complete_inspection))
        expect(page).to have_content(I18n.t("inspections.messages.cannot_edit_complete"))
      end
    end
  end

  private

  def select_unit_button(unit)
    within "li", text: unit.name do
      click_button I18n.t("units.actions.select")
    end
  end

  def expect_unit_details(unit)
    expect(page).to have_content(unit.name)
    expect(page).to have_content(unit.serial)
    expect(page).to have_content(unit.manufacturer)
  end

  def expect_units_visible(*units)
    units.each { |unit| expect(page).to have_content(unit.name) }
  end

  def expect_units_not_visible(*units)
    units.each { |unit| expect(page).not_to have_content(unit.name) }
  end

  def create_complete_inspection
    create(:inspection, :with_complete_assessments, user: user, unit: unit1).tap do |insp|
      # Mark as complete
      insp.update!(complete_date: Time.current)
    end
  end
end
