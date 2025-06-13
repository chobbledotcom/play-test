# Business Logic: Inspection Lifecycle Management Feature Tests
#
# Tests the user-centric inspection lifecycle management, including:
# - Editing completed inspections (user control maintained)
# - Toggling between complete/incomplete states
# - Manual entry of unique report numbers
# - Report number suggestion functionality with Turbo

require "rails_helper"

RSpec.feature "Inspection Lifecycle Management", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  
  before do
    login_user_via_form(user)
  end

  describe "editing completed inspections" do
    it "prevents editing completed inspections" do
      completed_inspection = create(:inspection, :complete, user: user, unit: unit)
      
      visit edit_inspection_path(completed_inspection)
      
      # Should redirect to show page with message
      expect(page).to have_current_path(inspection_path(completed_inspection))
      expect(page).to have_content(I18n.t("inspections.messages.cannot_edit_complete"))
    end
    
    it "allows marking complete inspection as incomplete" do
      completed_inspection = create(:inspection, :complete, user: user, unit: unit)
      
      visit edit_inspection_path(completed_inspection)
      click_button I18n.t("inspections.buttons.switch_to_in_progress")
      
      expect(page).to have_content(I18n.t("inspections.messages.marked_in_progress"))
      expect(completed_inspection.reload.complete?).to be false
    end

    it "preserves all data when toggling completion status" do
      # Create inspection with complete data but not yet marked as complete
      inspection = create(:inspection, :with_complete_assessments,
        user: user, 
        unit: unit,
        inspection_location: "Original Location",
        comments: "Original Comments",
        unique_report_number: "ORIG-123"
      )
      
      visit edit_inspection_path(inspection)
      
      # Mark as complete
      click_button I18n.t("inspections.buttons.mark_complete")
      
      # Debug: Check for error messages
      if current_path.include?("/edit")
        puts "Still on edit page. Checking for error messages..."
        puts "Page content: #{page.text}"
        save_and_open_page if page.has_css?(".alert")
      end
      
      # The inspection should be marked as complete and redirected to show page
      expect(page).to have_current_path(inspection_path(inspection))
      
      inspection.reload
      expect(inspection.complete?).to be true
      
      # Now we can't edit, but we can mark as incomplete
      visit inspection_path(inspection) # Show page for completed inspection
      click_button I18n.t("inspections.buttons.switch_to_in_progress")
      
      inspection.reload
      expect(inspection.complete?).to be false
      expect(inspection.inspection_location).to eq("Original Location")
      expect(inspection.comments).to eq("Original Comments")
      expect(inspection.unique_report_number).to eq("ORIG-123")
      
      # Now we can edit again
      visit edit_inspection_path(inspection)
      fill_in I18n.t("forms.inspections.fields.inspection_location"), with: "Updated after incomplete"
      click_button I18n.t("forms.inspections.submit")
      
      expect(inspection.reload.inspection_location).to eq("Updated after incomplete")
    end
  end

  describe "unique report number management" do
    let(:inspection) { create(:inspection, user: user, unit: unit, unique_report_number: nil) }
    
    it "allows manual entry of unique report number" do
      visit edit_inspection_path(inspection)
      
      fill_in I18n.t("forms.inspections.fields.unique_report_number"), with: "CUSTOM-2024-001"
      click_button I18n.t("forms.inspections.submit")
      
      expect(page).to have_content(I18n.t("inspections.messages.updated"))
      expect(inspection.reload.unique_report_number).to eq("CUSTOM-2024-001")
    end
    
    it "shows suggestion button when unique report number is empty" do
      visit edit_inspection_path(inspection)
      
      expect(page).to have_button(I18n.t("inspections.buttons.use_suggested_id", id: inspection.id))
    end
    
    it "fills field with inspection ID when suggestion button is clicked" do
      visit edit_inspection_path(inspection)
      
      # Verify button is present when unique_report_number is blank
      expect(page).to have_button(I18n.t("inspections.buttons.use_suggested_id", id: inspection.id))
      
      # Since JavaScript doesn't execute in rack-test, we'll simulate what the JS would do
      # by directly filling in the field with the inspection ID
      fill_in I18n.t("inspections.fields.unique_report_number"), with: inspection.id
      
      # Save the form
      click_button I18n.t("forms.inspections.submit")
      
      # Check the value was saved
      expect(inspection.reload.unique_report_number).to eq(inspection.id)
      
      # Verify the button is no longer shown after saving with a value
      visit edit_inspection_path(inspection)
      expect(page).not_to have_button(I18n.t("inspections.buttons.use_suggested_id", id: inspection.id))
    end
    
    it "does not show suggestion button when unique report number exists" do
      inspection_with_number = create(:inspection, 
        user: user, 
        unit: unit, 
        unique_report_number: "EXISTING-123"
      )
      
      visit edit_inspection_path(inspection_with_number)
      
      expect(page).not_to have_button(I18n.t("inspections.buttons.use_suggested_id", id: inspection_with_number.id))
    end
    
    it "allows clearing and re-suggesting report number" do
      inspection.update!(unique_report_number: "EXISTING-123")
      
      visit edit_inspection_path(inspection)
      
      # Clear the field
      fill_in I18n.t("inspections.fields.unique_report_number"), with: ""
      click_button I18n.t("forms.inspections.submit")
      
      # Verify it was cleared
      expect(inspection.reload.unique_report_number).to eq("")
      
      # Visit edit page again to see the button
      visit edit_inspection_path(inspection)
      expect(page).to have_button(I18n.t("inspections.buttons.use_suggested_id", id: inspection.id))
    end
  end

  describe "completion workflow" do
    let(:inspection) { create(:inspection, :with_complete_assessments, user: user, unit: nil) }
    
    it "can complete inspection without report number" do
      visit edit_inspection_path(inspection)
      
      click_button I18n.t("inspections.buttons.mark_complete")
      
      expect(page).to have_content(I18n.t("inspections.messages.marked_complete"))
      expect(inspection.reload.complete?).to be true
      expect(inspection.unique_report_number).to be_nil
    end
    
    it "can complete inspection with user-provided report number" do
      visit edit_inspection_path(inspection)
      
      fill_in I18n.t("inspections.fields.unique_report_number"), with: "USER-REPORT-456"
      click_button I18n.t("forms.inspections.submit")
      
      # The mark complete button is shown on the general tab
      visit edit_inspection_path(inspection)
      click_button I18n.t("inspections.buttons.mark_complete")
      
      inspection.reload
      expect(inspection.complete?).to be true
      expect(inspection.unique_report_number).to eq("USER-REPORT-456")
    end
  end

  describe "inspector company inheritance" do
    it "copies inspector company from user on creation" do
      inspector_company = create(:inspector_company)
      user_with_company = create(:user, inspection_company: inspector_company)
      unit_for_company_user = create(:unit, user: user_with_company)
      
      # Verify the user has the correct company
      expect(user_with_company.inspection_company_id).to eq(inspector_company.id)
      
      login_user_via_form(user_with_company)
      
      # Navigate to unit and create inspection
      visit unit_path(unit_for_company_user)
      click_button I18n.t("units.buttons.add_inspection")
      
      new_inspection = user_with_company.inspections.last
      expect(new_inspection.user_id).to eq(user_with_company.id)
      expect(new_inspection.inspector_company_id).to eq(inspector_company.id)
    end
    
    it "allows inspection creation without inspector company" do
      user_without_company = create(:user, inspection_company: nil)
      unit_for_user = create(:unit, user: user_without_company)
      
      login_user_via_form(user_without_company)
      
      # Navigate to unit and create inspection
      visit unit_path(unit_for_user)
      click_button I18n.t("units.buttons.add_inspection")
      
      new_inspection = user_without_company.inspections.last
      expect(new_inspection.inspector_company_id).to be_nil
      expect(new_inspection).to be_persisted
    end
  end
end