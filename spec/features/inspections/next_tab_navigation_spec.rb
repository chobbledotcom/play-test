require "rails_helper"

RSpec.feature "Next tab navigation", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, unit: unit, user: user) }

  before do
    sign_in(user)
  end

  scenario "suggests next incomplete tab when current tab is complete" do
    # Start on inspection tab which is complete
    visit edit_inspection_path(inspection, tab: "inspection")

    # Save the form - find the submit input directly for JS tests
    find("input[type='submit']").click

    # Should suggest the first incomplete assessment tab
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).to have_link(
      I18n.t("inspections.buttons.continue_to_tab",
        tab_name: I18n.t("forms.user_height.header"))
    )
  end

  scenario "suggests next tab forward when current tab is incomplete" do
    # Inspection already has width, length, height as nil by default
    visit edit_inspection_path(inspection, tab: "inspection")

    # Save the form without filling required fields
    find("input[type='submit']").click

    # Should suggest the next tab with incomplete count (3 fields: width, length, height)
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).to have_link(
      I18n.t("inspections.buttons.continue_to_tab_with_incomplete",
        count: 3,
        tab_name: I18n.t("forms.user_height.header"))
    )
  end

  scenario "suggests results tab when all assessments are complete" do
    # Create a completed inspection which has all assessments complete
    completed_inspection = create(:inspection, :completed, user: user, unit: unit)

    # Visit the last assessment tab
    last_tab = completed_inspection.applicable_tabs[-2] # -2 because results is last
    visit edit_inspection_path(completed_inspection, tab: last_tab)

    # Save the form - find the submit input directly for JS tests
    find("input[type='submit']").click

    # Should suggest results tab
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).to have_link(
      I18n.t("inspections.buttons.continue_to_tab",
        tab_name: I18n.t("forms.results.header"))
    )
  end

  scenario "no next tab link when on results tab and everything is complete" do
    # Create a completed inspection which has all assessments complete
    completed_inspection = create(:inspection, :completed, user: user, unit: unit)
    completed_inspection.update!(passed: true)

    # Visit results tab
    visit edit_inspection_path(completed_inspection, tab: "results")

    # Save the form - find the submit input directly for JS tests
    find("input[type='submit']").click

    # Should not suggest any next tab
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).not_to have_link(I18n.t("inspections.buttons.continue_to_tab", tab_name: ""))
  end
end
