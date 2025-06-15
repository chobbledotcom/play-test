require "rails_helper"

RSpec.feature "Inspection Prefilling Comment Fields", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before { sign_in(user) }

  # Helper to find comment checkbox and textarea for a field
  def verify_field_and_comment(field_label, expected_value, expected_comment)
    # Find the main field and verify its value
    field = find_field(field_label)
    expect(field.value).to eq(expected_value.to_s)

    # Find the form grid containing this field and its comment
    form_grid = field.find(:xpath, "./ancestor::div[contains(@class, 'form-grid')]")

    within(form_grid) do
      # The comment checkbox should be checked
      comment_label = find("label", text: I18n.t("shared.comment"))
      comment_checkbox = comment_label.find('input[type="checkbox"]')
      expect(comment_checkbox).to be_checked

      # The comment textarea should have the expected value
      comment_textarea = find("textarea")
      expect(comment_textarea.value).to eq(expected_comment)
    end
  end

  scenario "prefills comment fields from previous inspection" do
    # Create a completed first inspection with comments
    first_inspection = create(:inspection, :with_complete_assessments,
      user: user,
      unit: unit,
      width: 5.0,
      width_comment: "Custom width measurement",
      length: 4.0,
      length_comment: "Length includes platform")

    # Update structure assessment with comments
    first_inspection.structure_assessment.update!(
      step_ramp_size: 12.5,
      step_ramp_size_comment: "Measured at steepest angle"
    )

    first_inspection.update!(complete_date: Time.current)

    # Create a second inspection from the unit page
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    # Navigate to structure assessment tab
    click_link I18n.t("forms.structure.header")

    # Verify step/ramp size field and comment are prefilled
    verify_field_and_comment(
      I18n.t("forms.structure.fields.step_ramp_size"),
      "12.5",
      "Measured at steepest angle"
    )

    # Go back to main inspection form
    click_link I18n.t("forms.inspection.header")

    # Verify width field and comment are prefilled
    verify_field_and_comment(
      I18n.t("forms.inspection.fields.width"),
      "5",
      "Custom width measurement"
    )

    # Verify length field and comment are prefilled
    verify_field_and_comment(
      I18n.t("forms.inspection.fields.length"),
      "4",
      "Length includes platform"
    )

    # Verify form can be saved successfully with all the prefilled data
    click_button I18n.t("forms.inspection.submit")
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
  end
end
