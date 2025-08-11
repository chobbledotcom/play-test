# typed: false

require "rails_helper"

RSpec.feature "Dirty form warning", js: true do
  include InspectionTestHelpers

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) { create(:inspection, user:, unit:) }

  before do
    sign_in(user)
    visit edit_inspection_path(inspection)
  end

  scenario "tracks form changes and provides save options" do
    expect(page).not_to have_css("#dirty-form-indicator", visible: true)

    fill_in_form :inspection, :inspection_date, 1.day.ago.strftime("%Y-%m-%d")
    expect(page).to have_css("#dirty-form-indicator", visible: true)
    expect(page).to have_content("Unsaved changes")

    within("#dirty-form-indicator") do
      click_button "Save"
    end

    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).not_to have_css("#dirty-form-indicator", visible: true)
  end

  scenario "warns before navigating away with unsaved changes" do
    fill_in_form :inspection, :inspection_date, 2.days.ago.strftime("%Y-%m-%d")

    dismiss_confirm do
      click_link I18n.t("inspections.buttons.qr_and_pdf")
    end
    expect(page).to have_current_path(edit_inspection_path(inspection))

    accept_confirm do
      click_link I18n.t("inspections.buttons.qr_and_pdf")
    end
    expect(page).to have_current_path(inspection_path(inspection))
  end
end
