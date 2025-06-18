require "rails_helper"

RSpec.feature "Inspection incomplete fields display", type: :feature do
  include InspectionTestHelpers
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) { create(:inspection, unit:, user:, inspection_location: nil) }

  before do
    sign_in(user)
  end

  def expect_incomplete_fields_display
    expect(page).to have_content("Show")
    expect(page).to have_content("incomplete field")
  end

  def expand_incomplete_fields
    find("details#incomplete_fields_inspection summary").click
  end

  scenario "displays incomplete fields on inspection edit page" do
    visit edit_inspection_path(inspection)

    within("#mark-as-complete") do
      expect_incomplete_fields_display
      expand_incomplete_fields

      expect(page).to have_content(I18n.t("assessments.incomplete_fields.description"))
      expect(page).to have_content(I18n.t("forms.inspection.fields.inspection_location"))

      expect(page).to have_button(I18n.t("inspections.buttons.mark_complete"))
    end
  end

  scenario "shows incomplete fields from assessments with section prefix" do
    inspection.user_height_assessment.update!(tallest_user_height: nil)

    visit edit_inspection_path(inspection)

    expect_incomplete_fields_display
    expand_incomplete_fields

    expect(page).to have_content(I18n.t("forms.inspection.fields.inspection_location"))

    within ".incomplete-fields-content" do
      field_name = I18n.t("forms.user_height.fields.tallest_user_height")
      expect(page).to have_content(field_name)
    end
  end

  scenario "does not show incomplete fields when inspection is complete" do
    completed_inspection = create(:inspection, :completed, unit:, user:)

    visit edit_inspection_path(completed_inspection)

    expect(page).not_to have_css("details#incomplete_fields_inspection")
  end

  scenario "excludes optional assessment incomplete fields" do
    inspection.update!(has_slide: false)
    inspection.slide_assessment.update!(runout: nil)

    visit edit_inspection_path(inspection)

    expand_incomplete_fields

    expect(page).not_to have_content(I18n.t("forms.slide.header"))
  end
end
