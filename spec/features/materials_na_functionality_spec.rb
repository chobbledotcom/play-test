# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Materials Assessment N/A Functionality", type: :feature do
  let(:company) { create(:inspector_company) }
  let(:user) do
    create(:user, inspection_company: company, active_until: 2.days.from_now)
  end
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    sign_in(user)
  end

  scenario "saving N/A for ropes assessment" do
    # Go to materials assessment form
    visit edit_inspection_path(inspection, tab: "materials")

    # Choose the N/A radio button for ropes
    field_id = "assessments_materials_assessment_ropes_pass_na"
    choose field_id

    # Submit the form
    click_button "Save Assessment"

    # Should see success message
    expect(page).to have_content("Inspection updated successfully")

    # Reload the page to verify it was saved
    visit edit_inspection_path(inspection, tab: "materials")

    # N/A checkbox should still be checked
    field_id = "assessments_materials_assessment_ropes_pass_na"
    expect(page).to have_checked_field(field_id)

    # Verify in the database
    inspection.reload
    expect(inspection.materials_assessment.ropes_pass).to eq("na")
  end
end
