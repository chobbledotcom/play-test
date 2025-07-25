require "rails_helper"

RSpec.feature "Indoor only field in inspection form", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    sign_in(user)
  end

  scenario "displays indoor_only field in the form" do
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    unit_config_section = I18n.t("forms.inspection.sections.unit_configuration")
    within_fieldset unit_config_section do
      indoor_only_field = I18n.t("forms.inspection.fields.indoor_only")
      expect(page).to have_content(indoor_only_field)
      field_selector = "inspection[indoor_only]"
      expect(page).to have_field(field_selector, with: "false", visible: false)
    end
  end

  scenario "saves indoor_only field when creating inspection" do
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    fill_in_inspection_form

    unit_config_section = I18n.t("forms.inspection.sections.unit_configuration")
    within_fieldset unit_config_section do
      indoor_only_field = I18n.t("forms.inspection.fields.indoor_only")
      choose_yes_no(indoor_only_field, true)
    end

    click_button I18n.t("forms.inspection.submit")

    inspection = Inspection.last
    expect(inspection.indoor_only).to be true
  end

  scenario "anchorage assessment is hidden when indoor_only is true" do
    inspection = create(:inspection, unit: unit, user: user, indoor_only: true)

    visit edit_inspection_path(inspection)

    # Should not see anchorage assessment tab
    expect(page).not_to have_content(I18n.t("inspections.tabs.anchorage"))
  end

  scenario "anchorage assessment is shown when indoor_only is false" do
    inspection = create(:inspection, unit: unit, user: user, indoor_only: false)

    visit edit_inspection_path(inspection)

    # Should see anchorage assessment tab
    expect(page).to have_content(I18n.t("inspections.tabs.anchorage"))
  end

  private

  def fill_in_inspection_form
    fill_in I18n.t("forms.inspection.fields.unique_report_number"),
      with: "TEST001"
    fill_in I18n.t("forms.inspection.fields.inspection_date"),
      with: Date.current.strftime("%Y-%m-%d")
    fill_in I18n.t("forms.inspection.fields.width"), with: "5.5"
    fill_in I18n.t("forms.inspection.fields.length"), with: "6.0"
    fill_in I18n.t("forms.inspection.fields.height"), with: "4.5"

    unit_config_section = I18n.t("forms.inspection.sections.unit_configuration")
    within_fieldset unit_config_section do
      has_slide_field = I18n.t("forms.inspection.fields.has_slide")
      enclosed_field = I18n.t("forms.inspection.fields.is_totally_enclosed")
      indoor_only_field = I18n.t("forms.inspection.fields.indoor_only")
      choose_yes_no(has_slide_field, false)
      choose_yes_no(enclosed_field, false)
      choose_yes_no(indoor_only_field, false)
    end
  end
end
