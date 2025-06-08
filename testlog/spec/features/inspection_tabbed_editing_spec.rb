require "rails_helper"

RSpec.feature "Inspection Tabbed Editing", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, inspection_company: inspector_company) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, :in_progress, user: user, unit: unit, inspector_company: inspector_company) }

  before do
    # Login as the user
    login_user_via_form(user)
  end

  describe "tabbed layout" do
    before { visit edit_inspection_path(inspection) }

    it "displays the inspection overview section" do
      expect(page).to have_content(I18n.t("inspections.headers.overview"))
      expect(page).to have_content(I18n.t("inspections.fields.unit_name"))
      expect(page).to have_content(I18n.t("inspections.fields.serial"))
      expect(page).to have_content(I18n.t("inspections.fields.status"))
      expect(page).to have_content(I18n.t("inspections.fields.progress"))
    end

    it "displays all expected tabs" do
      expect(page).to have_link(I18n.t("inspections.tabs.general"))
      expect(page).to have_link(I18n.t("inspections.tabs.user_height"))
      expect(page).to have_link(I18n.t("inspections.tabs.structure"))
      expect(page).to have_link(I18n.t("inspections.tabs.anchorage"))
      expect(page).to have_link(I18n.t("inspections.tabs.materials"))
      expect(page).to have_link(I18n.t("inspections.tabs.fan"))

      # Slide tab should not appear for bounce house units
      expect(page).not_to have_link(I18n.t("inspections.tabs.slide"))
    end

    it "shows slide tab for units with slides" do
      slide_unit = create(:unit, user: user, has_slide: true)
      slide_inspection = create(:inspection, user: user, unit: slide_unit)

      visit edit_inspection_path(slide_inspection)
      expect(page).to have_link(I18n.t("inspections.tabs.slide"))

      # Test with factory trait
      combo_unit = create(:unit, :with_slide, user: user)
      combo_inspection = create(:inspection, user: user, unit: combo_unit)

      visit edit_inspection_path(combo_inspection)
      expect(page).to have_link(I18n.t("inspections.tabs.slide"))
    end

    it "shows enclosed tab only for totally enclosed units" do
      regular_unit = create(:unit, user: user)
      regular_inspection = create(:inspection, user: user, unit: regular_unit)

      visit edit_inspection_path(regular_inspection)
      expect(page).not_to have_link(I18n.t("inspections.tabs.enclosed"))

      enclosed_unit = create(:unit, user: user, is_totally_enclosed: true)
      enclosed_inspection = create(:inspection, user: user, unit: enclosed_unit)

      visit edit_inspection_path(enclosed_inspection)
      expect(page).to have_link(I18n.t("inspections.tabs.enclosed"))
    end

    it "shows the general tab as active by default" do
      expect(page).to have_css(".tab-link.active", text: I18n.t("inspections.tabs.general"))
    end

    it "can navigate between tabs" do
      click_link I18n.t("inspections.tabs.user_height")
      expect(current_url).to include("tab=user_height")
      expect(page).to have_content("Assessment")
      expect(page).to have_content("User Height Assessment")

      click_link I18n.t("inspections.tabs.general")
      expect(page).to have_css(".tab-link.active", text: I18n.t("inspections.tabs.general"))
    end
  end

  describe "general tab functionality" do
    before do
      # Ensure inspector company is created before visiting the page
      inspector_company
      visit edit_inspection_path(inspection)
    end

    it "displays all general form fields" do
      expect(page).to have_field(I18n.t("inspections.fields.unit_select"))
      expect(page).to have_field(I18n.t("inspections.fields.inspection_location"))
      expect(page).to have_field(I18n.t("inspections.fields.inspection_date"))
      expect(page).to have_field(I18n.t("inspections.fields.unique_report_number"))
      expect(page).to have_field(I18n.t("inspections.fields.status"))
      expect(page).to have_field(I18n.t("inspections.fields.pass"))
      expect(page).to have_field(I18n.t("inspections.fields.comments"))

      # These are read-only calculated fields, not form inputs
      expect(page).to have_content(I18n.t("inspections.fields.reinspection_date"))
      expect(page).to have_content(I18n.t("inspections.fields.inspector_company"))
    end

    it "displays current unit details when unit is selected" do
      expect(page).to have_content(I18n.t("inspections.headers.current_unit"))
      expect(page).to have_content(unit.name)
      expect(page).to have_content(unit.serial)
      expect(page).to have_content(unit.manufacturer)
    end

    it "can update basic inspection fields" do
      fill_in I18n.t("inspections.fields.inspection_location"), with: "Updated Location"
      fill_in I18n.t("inspections.fields.comments"), with: "Updated comments"

      click_button I18n.t("inspections.buttons.update")

      expect(page).to have_content(I18n.t("inspections.messages.updated"))

      inspection.reload
      expect(inspection.inspection_location).to eq("Updated Location")
      expect(inspection.comments).to eq("Updated comments")
    end

    it "shows inspector company for regular users" do
      # Regular users see their assigned company, not a dropdown
      expect(page).to have_content(I18n.t("inspections.fields.inspector_company"))
      expect(page).to have_content(inspector_company.name)
      expect(page).to have_content("Set in your user settings")
    end

    it "can update inspection status" do
      select I18n.t("inspections.status.in_progress"), from: I18n.t("inspections.fields.status")
      click_button I18n.t("inspections.buttons.update")

      inspection.reload
      expect(inspection.status).to eq("in_progress")
    end

    it "can toggle pass/fail status" do
      check I18n.t("inspections.fields.pass")
      click_button I18n.t("inspections.buttons.update")

      inspection.reload
      expect(inspection.passed).to be true
    end

    it "validates required fields" do
      # Clear required fields
      fill_in I18n.t("inspections.fields.inspection_location"), with: ""

      click_button I18n.t("inspections.buttons.update")

      expect(page).to have_content(I18n.t("inspections.errors.header", count: 1))
    end

    it "can change unit selection" do
      other_unit = create(:unit, user: user, name: "Different Unit")

      # Refresh the page to ensure new unit is loaded
      visit edit_inspection_path(inspection)

      expect(page).to have_select(I18n.t("inspections.fields.unit_select"),
        with_options: [other_unit.name])

      select other_unit.name, from: I18n.t("inspections.fields.unit_select")
      click_button I18n.t("inspections.buttons.update")

      inspection.reload
      expect(inspection.unit).to eq(other_unit)
    end
  end

  describe "auto-save markup" do
    before { visit edit_inspection_path(inspection) }

    it "includes auto-save data attributes and status elements" do
      expect(page).to have_css('form[data-autosave="true"]')
      expect(page).to have_css("[data-autosave-status]", visible: false)
    end
  end

  describe "navigation and workflow" do
    before { visit edit_inspection_path(inspection) }

    it "preserves form data when switching tabs" do
      fill_in I18n.t("inspections.fields.inspection_location"), with: "Test Location Data"
      # Save the form first
      click_button I18n.t("inspections.buttons.update")

      # Navigate to user height tab (which will show placeholder)
      visit edit_inspection_path(inspection, tab: "user_height")
      expect(page).to have_content("Assessment")

      # Navigate back to general tab
      visit edit_inspection_path(inspection)

      expect(page).to have_field(I18n.t("inspections.fields.inspection_location"), with: "Test Location Data")
    end

    it "includes delete button" do
      expect(page).to have_button(I18n.t("inspections.buttons.delete"))
      # Note: Cannot test confirmation dialog without JavaScript driver
    end
  end

  describe "accessibility and UX" do
    before { visit edit_inspection_path(inspection) }

    it "has proper heading structure" do
      expect(page).to have_css("h1", text: I18n.t("inspections.titles.edit"))
      expect(page).to have_css("h2", text: I18n.t("inspections.headers.overview"))
      expect(page).to have_css("legend", text: I18n.t("inspections.sections.unit_details"))
    end

    it "has proper form labels for accessibility" do
      expect(page).to have_css('label[for*="inspection_unit_id"]')
      expect(page).to have_css('label[for*="inspection_location"]')
      expect(page).to have_css('label[for*="inspection_passed"]')
    end

    it "shows completion percentage in overview" do
      expect(page).to have_content(I18n.t("inspections.fields.progress"))
      expect(page).to have_content("%") # Should show percentage
    end
  end

  describe "error handling" do
    before { visit edit_inspection_path(inspection) }

    it "displays validation errors clearly" do
      # Ensure we're testing an inspection with a status that requires location
      inspection.update!(status: "in_progress")
      visit edit_inspection_path(inspection)

      fill_in I18n.t("inspections.fields.inspection_location"), with: ""
      click_button I18n.t("inspections.buttons.update")

      expect(page).to have_css("aside") # Error container
      expect(page).to have_content("Inspection location can't be blank")
    end

    it "only shows units belonging to the current user" do
      other_user = create(:user)
      other_unit = create(:unit, user: other_user, name: "Other User's Unit")

      # Should not see other user's units in dropdown
      expect(page).not_to have_select(I18n.t("inspections.fields.unit_select"),
        with_options: [other_unit.name])

      # Should see own units
      expect(page).to have_select(I18n.t("inspections.fields.unit_select"),
        with_options: [unit.name])
    end
  end
end
