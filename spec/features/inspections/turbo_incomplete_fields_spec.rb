require "rails_helper"

RSpec.feature "Turbo incomplete fields update", js: true do
  include InspectionTestHelpers

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) { 
    # Create a completed inspection first
    completed = create(:inspection, :completed, user:, unit:)
    
    # Un-complete it so we can edit it
    completed.update!(complete_date: nil)
    
    # Then remove just the inspection_location to have exactly 1 incomplete field
    completed.update_column(:inspection_location, nil)
    completed
  }

  before do
    sign_in(user)
  end

  scenario "incomplete fields count updates dynamically when saving form" do
    visit edit_inspection_path(inspection)
    
    # Find and verify initial incomplete fields count
    expect(page).to have_css("summary.incomplete-fields-summary")
    summary = find("summary.incomplete-fields-summary")
    expect(summary.text).to match(/Show 1 incomplete field/)
    
    # Fill in the missing field
    fill_in I18n.t("forms.inspection.fields.inspection_location"), with: "Test Location"
    
    # Submit the form
    click_button I18n.t("forms.inspection.submit")
    
    # Wait for Turbo to update the frame
    # The incomplete fields should now be 0 and the count should update
    expect(page).to have_css("#mark-as-complete", wait: 3)
    
    # The button should now be visible since there are no incomplete fields
    within("#mark-as-complete") do
      expect(page).to have_button(I18n.t("inspections.buttons.mark_complete"))
      expect(page).not_to have_css("summary.incomplete-fields-summary")
    end
  end
end