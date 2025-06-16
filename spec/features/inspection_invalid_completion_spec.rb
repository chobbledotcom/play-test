require "rails_helper"

RSpec.feature "Invalid inspection completion validation", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) { create(:inspection, unit:, user:) }

  before do
    sign_in(user)
  end

  scenario "prevents viewing an inspection marked complete with validation errors" do
    # Manually mark inspection as complete without filling assessments
    # NOTE: In normal usage, use create(:inspection, :completed) helper instead
    inspection.update_column(:complete_date, Time.current)

    # Attempt to view the inspection - should raise DATA INTEGRITY ERROR
    expect {
      visit inspection_path(inspection)
    }.to raise_error(RuntimeError, /DATA INTEGRITY ERROR/)
  end

  scenario "prevents editing an inspection marked complete with validation errors" do
    # Manually mark inspection as complete without filling assessments
    # NOTE: In normal usage, use create(:inspection, :completed) helper instead
    inspection.update_column(:complete_date, Time.current)

    # Attempt to edit the inspection - should raise DATA INTEGRITY ERROR
    expect {
      visit edit_inspection_path(inspection)
    }.to raise_error(RuntimeError, /DATA INTEGRITY ERROR/)
  end

  scenario "allows viewing properly completed inspections" do
    # Create a properly completed inspection using factory
    # This uses the :completed trait which ensures all assessments are complete
    completed_inspection = create_completed_inspection(unit:, user:)

    # Should be able to view without errors
    visit inspection_path(completed_inspection)
    expect(page).to have_content(completed_inspection.unit.serial)
    expect(page).not_to have_content("validation errors")
  end
end
