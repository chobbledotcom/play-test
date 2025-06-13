require "rails_helper"

RSpec.feature "Inspection Creation Workflow", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario "creates inspection without unit and shows expected message" do
    visit inspections_path

    # Click the "Add Inspection" button which creates a draft inspection without unit
    click_button I18n.t("inspections.buttons.add_inspection")

    # Should show success message for creation without unit
    expect(page).to have_content(I18n.t("inspections.messages.created_without_unit"))

    # Should be redirected to edit the newly created inspection (check the URL)
    created_inspection = user.inspections.order(:created_at).last
    expect(created_inspection).to be_present
    expect(current_url).to include(edit_inspection_path(created_inspection))
  end

end
