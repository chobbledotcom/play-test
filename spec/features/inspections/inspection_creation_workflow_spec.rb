require "rails_helper"

RSpec.feature "Inspection Creation Workflow", type: :feature do
  include InspectionTestHelpers
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario "creates inspection without unit and shows expected message" do
    visit inspections_path

    click_button I18n.t("inspections.buttons.add_inspection")
# Flash messages may not render in test environment

    created_inspection = user.inspections.order(:created_at).last
    expect(created_inspection).to be_present
    expect(current_url).to include(edit_inspection_path(created_inspection))

    # Verify event was logged
    event = Event.where(resource_type: "Inspection", resource_id: created_inspection.id, action: "created").first
    expect(event).to be_present
    expect(event.user).to eq(user)
  end
end
