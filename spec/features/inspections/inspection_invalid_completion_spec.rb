require "rails_helper"

RSpec.feature "Invalid inspection completion validation", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) { create(:inspection, unit:, user:) }

  before do
    sign_in(user)
  end

  scenario "prevents viewing an inspection marked complete with validation errors" do
    inspection.update_column(:complete_date, Time.current)

    expect {
      visit inspection_path(inspection)
    }.to raise_error(RuntimeError, /DATA INTEGRITY ERROR/)
  end

  scenario "prevents editing an inspection marked complete with validation errors" do
    inspection.update_column(:complete_date, Time.current)

    expect {
      visit edit_inspection_path(inspection)
    }.to raise_error(RuntimeError, /DATA INTEGRITY ERROR/)
  end

  scenario "allows viewing properly completed inspections" do
    completed_inspection = create(:inspection, :completed, unit:, user:)

    visit inspection_path(completed_inspection)
    expect(page).to have_content(completed_inspection.unit.serial)
    expect(page).not_to have_content("validation errors")
  end
end
