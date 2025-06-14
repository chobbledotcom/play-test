require "rails_helper"

RSpec.feature "Complete Inspection Workflow", type: :feature do
  let(:user) { create(:user) }
  
  before do
    sign_in(user)
  end

  scenario "creates unit, fills out all inspection fields, and completes inspection" do
    # Step 1: Create a new unit
    visit units_path
    click_button I18n.t("units.buttons.add_unit")
    
    # Fill out unit form
    fill_in I18n.t("forms.units.fields.name"), with: "Test Bouncy Castle"
    fill_in I18n.t("forms.units.fields.serial"), with: "TEST-#{SecureRandom.hex(4).upcase}"
    fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
    fill_in I18n.t("forms.units.fields.owner"), with: "Test Owner"
    fill_in I18n.t("forms.units.fields.manufacture_date"), with: "2024-01-01"
    fill_in I18n.t("forms.units.fields.description"), with: "A test bouncy castle for testing"
    
    click_button I18n.t("forms.units.submit")
    
    # Verify unit was created
    expect(page).to have_content(I18n.t("units.messages.created"))
    unit = Unit.last
    expect(unit.name).to eq("Test Bouncy Castle")
    
    # Step 2: Create an inspection for this unit
    click_button I18n.t("units.buttons.add_inspection")
    
    # Should be on edit inspection page
    expect(page).to have_content(I18n.t("inspections.titles.edit"))
    inspection = Inspection.last
    expect(inspection.unit).to eq(unit)
    
    # Step 3: Fill out the general inspection tab
    # We're already on the inspections tab by default
    fill_in I18n.t("forms.inspections.fields.inspection_date"), with: Date.current
    fill_in I18n.t("forms.inspections.fields.inspection_location"), with: "Test Location"
    fill_in I18n.t("forms.inspections.fields.unique_report_number"), with: "TEST-REPORT-001"
    fill_in I18n.t("forms.inspections.fields.risk_assessment"), with: "Low risk - all safety features functional"
    
    # Mark as totally enclosed and with slide to test all assessment types
    check I18n.t("forms.inspections.fields.is_totally_enclosed")
    check I18n.t("forms.inspections.fields.has_slide")
    
    # Set dimensions for calculations
    fill_in I18n.t("forms.inspections.fields.width"), with: "5.5"
    fill_in I18n.t("forms.inspections.fields.length"), with: "6.0"
    fill_in I18n.t("forms.inspections.fields.height"), with: "4.5"
    
    click_button I18n.t("forms.inspections.submit")
    
    # Step 4: Go through each assessment tab and fill out all fields
    # Get all tab names from ASSESSMENT_TYPES
    assessment_tabs = Inspection::ASSESSMENT_TYPES.keys.map { |k| k.to_s.sub(/_assessment$/, "") }
    
    assessment_tabs.each do |tab_name|
      # Skip tabs that don't apply
      next if tab_name == "slide" && !inspection.reload.has_slide
      next if tab_name == "enclosed" && !inspection.reload.is_totally_enclosed
      
      # Navigate to the tab
      visit edit_inspection_path(inspection, tab: tab_name)
      
      # Get all fields for this form from i18n
      i18n_base = "forms.#{tab_name}"
      fields = I18n.t("#{i18n_base}.fields")
      
      # Fill out each field based on its type
      fields.each do |field_key, field_label|
        field_name = field_key.to_s
        
        # Determine field type and fill accordingly
        case field_name
        when /(_pass|_visible)$/
          # Pass/fail radio buttons - choose pass
          choose "#{field_label} - #{I18n.t('shared.pass')}", allow_label_click: true
        when /_comment$/
          # Comment fields
          fill_in field_label, with: "Test comment for #{field_name}"
        when /^num_/, /count$/, /number$/, /_size$/, /_height$/, /_width$/, /_length$/, /_depth$/, /_pressure$/
          # Numeric fields
          fill_in field_label, with: "2.5"
        when /^users_at_/
          # User capacity fields
          fill_in field_label, with: "10"
        when /serial$/
          # Serial number fields
          fill_in field_label, with: "SERIAL-123"
        when /^ropes$/
          # Special case for ropes field
          fill_in field_label, with: "25"
        else
          # Default to text field
          fill_in field_label, with: "Test value"
        end
      end
      
      # Save this assessment
      click_button I18n.t("#{i18n_base}.submit")
      
      # Verify we're back on the edit page
      expect(page).to have_content(I18n.t("inspections.titles.edit"))
    end
    
    # Step 5: Mark inspection as complete
    click_button I18n.t("inspections.buttons.complete")
    
    # Should redirect to inspection show page
    expect(page).to have_content(I18n.t("inspections.messages.marked_complete"))
    
    # Verify inspection is marked as complete
    inspection.reload
    expect(inspection.complete?).to be true
    expect(inspection.complete_date).to be_present
    
    # Step 6: Go back to edit page and verify all assessments show complete status
    visit edit_inspection_path(inspection)
    
    # For each assessment tab, verify it shows complete status
    assessment_tabs.each do |tab_name|
      next if tab_name == "slide" && !inspection.has_slide
      next if tab_name == "enclosed" && !inspection.is_totally_enclosed
      
      visit edit_inspection_path(inspection, tab: tab_name)
      
      # Each assessment should show completion status
      within(".assessment-status") do
        # Look for "Fields completed: X/X" where both numbers are the same
        completion_text = page.text
        if completion_text.match(/(\d+)\s*\/\s*(\d+)/)
          completed = $1.to_i
          total = $2.to_i
          expect(completed).to eq(total), "#{tab_name} assessment should show all fields completed"
          expect(completed).to be > 0, "#{tab_name} assessment should have some fields"
        end
      end
    end
    
    # Final verification: PDF should generate without errors
    visit inspection_path(inspection, format: :pdf)
    expect(page.status_code).to eq(200)
  end
end