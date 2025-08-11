# typed: false

require "rails_helper"

RSpec.feature "Inspection Prefilling Comment Fields", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before { sign_in(user) }

  define_method(:verify_field_and_comment) do |field_label, expected_value, expected_comment|
    field = find_field(field_label)
    expect(field.value).to eq(expected_value.to_s)

    form_grid = field.find(:xpath, "./ancestor::div[contains(@class, 'form-grid')]")

    within(form_grid) do
      comment_label = find("label", text: I18n.t("shared.comment"))
      comment_checkbox = comment_label.find('input[type="checkbox"]')
      expect(comment_checkbox).to be_checked

      comment_textarea = find("textarea")
      expect(comment_textarea.value).to eq(expected_comment)
    end
  end

  scenario "prefills comment fields from previous inspection" do
    first_inspection = create(:inspection, :completed,
      user: user,
      unit: unit,
      width: 5.0,
      width_comment: "Custom width measurement",
      length: 4.0,
      length_comment: "Length includes platform")

    first_inspection.structure_assessment.update!(
      step_ramp_size: 12,
      step_ramp_size_comment: "Measured at steepest angle"
    )

    first_inspection.update!(complete_date: Time.current)

    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    click_link I18n.t("forms.structure.header")

    verify_field_and_comment(
      I18n.t("forms.structure.fields.step_ramp_size"),
      "12",
      "Measured at steepest angle"
    )

    click_link I18n.t("forms.inspection.header")

    verify_field_and_comment(
      I18n.t("forms.inspection.fields.width"),
      "5.0",
      "Custom width measurement"
    )

    verify_field_and_comment(
      I18n.t("forms.inspection.fields.length"),
      "4.0",
      "Length includes platform"
    )

    submit_form :inspection
    expect_updated_message
  end
end
