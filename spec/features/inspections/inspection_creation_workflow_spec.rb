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

    expect(page).to have_content(I18n.t("inspections.messages.created_without_unit"))

    created_inspection = user.inspections.order(:created_at).last
    expect(created_inspection).to be_present
    expect(current_url).to include(edit_inspection_path(created_inspection))
  end
end
