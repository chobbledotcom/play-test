# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Turbo incomplete fields update", js: true do
  include InspectionTestHelpers

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) do
    create(:inspection, :completed, user:, unit:).tap do |insp|
      insp.update_columns(complete_date: nil)
      # Make an assessment field incomplete to have something to test with
      insp.user_height_assessment.update_column(:users_at_1000mm, nil)
    end
  end

  before do
    sign_in(user)
  end

  scenario "incomplete fields count updates dynamically when saving form" do
    visit edit_inspection_path(inspection)

    expect(page).to have_css("summary.incomplete-fields-summary")
    summary = find("summary.incomplete-fields-summary")
    expect(summary.text).to match(/Show 1 incomplete field/)

    visit edit_inspection_path(inspection, tab: "user_height")
    height_label = I18n.t("forms.user_height.fields.users_at_1000mm")
    fill_in height_label, with: "2"

    click_button I18n.t("forms.user_height.submit")

    # expect(page).to have_css("#mark-as-complete", wait: 3)

    within("#mark-as-complete") do
      expect(page).to have_button(I18n.t("inspections.buttons.mark_complete"))
      expect(page).not_to have_css("summary.incomplete-fields-summary")
    end
  end
end
