# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Next tab navigation", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, unit: unit, user: user) }

  before do
    sign_in(user)
  end

  # Since we're not using JS, we'll test the helper method behavior indirectly
  # The actual continue link is only shown in Turbo Stream responses
  scenario "saves successfully and redirects to show page" do
    # Start on inspection tab
    visit edit_inspection_path(inspection, tab: "inspection")

    # Save the form
    click_button "Save Inspection"

    # Should redirect to show page with success message
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(current_path).to eq(inspection_path(inspection))
  end

  scenario "saves assessment and redirects to show page" do
    # Visit an assessment tab
    visit edit_inspection_path(inspection, tab: "user_height")

    # Fill in some fields
    fill_in I18n.t("forms.user_height.fields.containing_wall_height"), with: "2.5"
    fill_in I18n.t("forms.user_height.fields.users_at_1000mm"), with: "3"

    # Save the assessment
    click_button "Save Assessment"

    # Should redirect to show page with success message
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(current_path).to eq(inspection_path(inspection))
  end
end
