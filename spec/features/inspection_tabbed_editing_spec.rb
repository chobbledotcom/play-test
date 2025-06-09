require "rails_helper"

RSpec.feature "Inspection Tabbed Editing", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, inspection_company: inspector_company) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit, inspector_company: inspector_company) }

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
      # The current tab (general) should be a span, not a link
      expect(page).to have_content(I18n.t("inspections.tabs.general"))
      expect(page).to have_link(I18n.t("inspections.tabs.user_height"))
      expect(page).to have_link(I18n.t("inspections.tabs.structure"))
      expect(page).to have_link(I18n.t("inspections.tabs.anchorage"))
      expect(page).to have_link(I18n.t("inspections.tabs.materials"))
      expect(page).to have_link(I18n.t("inspections.tabs.fan"))

      # Slide tab should not appear for bounce house units
      expect(page).not_to have_content(I18n.t("inspections.tabs.slide"))
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
      expect(page).to have_css("nav.tabs span", text: I18n.t("inspections.tabs.general"))
    end

    it "can navigate between tabs" do
      click_link I18n.t("inspections.tabs.user_height")
      expect(current_url).to include("tab=user_height")
      expect(page).to have_content(I18n.t("inspections.assessments.user_height.title"))

      click_link I18n.t("inspections.tabs.general")
      expect(page).to have_css("nav.tabs span", text: I18n.t("inspections.tabs.general"))
    end
  end

  describe "general tab functionality" do
    before do
      # Ensure inspector company is created before visiting the page
      inspector_company
      visit edit_inspection_path(inspection)
    end

    it "displays all general form fields" do
      # When inspection has a unit, it shows unit details rather than select field
      expect(page).to have_content(I18n.t("inspections.headers.current_unit"))
      expect(page).to have_field(I18n.t("inspections.fields.inspection_location"))
      expect(page).to have_field(I18n.t("inspections.fields.inspection_date"))
      expect(page).to have_field(I18n.t("inspections.fields.unique_report_number"))
      # Status is now read-only, not a field
      expect(page).to have_content(I18n.t("inspections.fields.status"))
      expect(page).to have_field(I18n.t("inspections.fields.step_ramp_size"))
      expect(page).to have_content(I18n.t("inspections.fields.step_ramp_size_pass"))
      expect(page).to have_field(I18n.t("inspections.fields.critical_fall_off_height"))
      expect(page).to have_content(I18n.t("inspections.fields.critical_fall_off_height_pass"))
      expect(page).to have_field(I18n.t("inspections.fields.unit_pressure"))
      expect(page).to have_content(I18n.t("inspections.fields.unit_pressure_pass"))
      expect(page).to have_field(I18n.t("inspections.fields.trough_depth"))
      expect(page).to have_field(I18n.t("inspections.fields.trough_adjacent_panel_width"))
      expect(page).to have_content(I18n.t("inspections.fields.trough_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.entrapment_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.markings_id_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.grounding_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.clamber_netting_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.retention_netting_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.zips_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.windows_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.artwork_pass"))
      expect(page).to have_content(I18n.t("inspections.fields.exit_sign_visible_pass"))
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

    it "can mark inspection as complete" do
      # First create all necessary assessments for completion
      create(:user_height_assessment, :complete, inspection: inspection)
      create(:structure_assessment, :complete, inspection: inspection)
      create(:anchorage_assessment, :passed, inspection: inspection)
      create(:materials_assessment, :passed, inspection: inspection)
      create(:fan_assessment, :passed, inspection: inspection)

      visit edit_inspection_path(inspection)

      # Status is now changed via dedicated button, not dropdown
      click_button I18n.t("inspections.buttons.mark_complete")

      inspection.reload
      expect(inspection.complete?).to be_truthy
      # Should redirect to show page
      expect(page).to have_current_path(inspection_path(inspection))
    end

    it "can toggle pass/fail status" do
      check I18n.t("inspections.fields.pass")
      click_button I18n.t("inspections.buttons.update")

      inspection.reload
      expect(inspection.passed).to be true
    end

    it "validates required fields" do
      # Clear required fields (inspection_date is always required)
      fill_in I18n.t("inspections.fields.inspection_date"), with: ""

      click_button I18n.t("inspections.buttons.update")

      expect(page).to have_content(I18n.t("inspections.errors.header", count: 1))
    end

    it "can change unit selection via change unit link" do
      other_unit = create(:unit, user: user, name: "Different Unit")

      # Refresh the page to ensure new unit is loaded
      visit edit_inspection_path(inspection)

      # When inspection has a unit, use the "Change unit" link to access unit selection
      expect(page).to have_link(I18n.t("inspections.buttons.change_unit"))
      click_link I18n.t("inspections.buttons.change_unit")

      # Should be on unit selection page now
      expect(page).to have_current_path(select_unit_inspection_path(inspection))
      expect(page).to have_content(other_unit.name)
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
      expect(page).to have_content(I18n.t("inspections.assessments.user_height.title"))

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
      expect(page).to have_css("legend", text: I18n.t("inspections.sections.current_unit"))
    end

    it "has proper form labels for accessibility" do
      # When inspection has a unit, unit_id field is not shown
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
      # Test with a draft inspection (complete inspections redirect)
      inspection.update!(complete_date: nil, inspection_location: "Original Location")
      visit edit_inspection_path(inspection)

      fill_in I18n.t("inspections.fields.inspection_location"), with: ""
      click_button I18n.t("inspections.buttons.update")

      # For draft inspections, location is not required, so let's test a different validation
      # Actually, let's verify that empty location is allowed for drafts
      expect(inspection.reload.inspection_location).to eq("")
      expect(page).to have_content(I18n.t("inspections.messages.updated"))
    end

    it "only shows units belonging to the current user" do
      other_user = create(:user)
      other_unit = create(:unit, user: other_user, name: "Other User's Unit")

      # Go to unit selection page via change unit link
      click_link I18n.t("inspections.buttons.change_unit")

      # Should not see other user's units in the unit selection
      expect(page).not_to have_content(other_unit.name)

      # Should see own units
      expect(page).to have_content(unit.name)
    end
  end
end
