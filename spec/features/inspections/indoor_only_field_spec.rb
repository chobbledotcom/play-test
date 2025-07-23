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

    within_fieldset I18n.t("forms.inspection.sections.unit_configuration") do
      expect(page).to have_content(I18n.t("forms.inspection.fields.indoor_only"))
      expect(page).to have_field("inspection[indoor_only]", with: "false", visible: false)
    end
  end

  scenario "saves indoor_only field when creating inspection" do
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    fill_in_inspection_form

    within_fieldset I18n.t("forms.inspection.sections.unit_configuration") do
      choose_yes_no(I18n.t("forms.inspection.fields.indoor_only"), true)
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
    fill_in I18n.t("forms.inspection.fields.inspection_location"),
      with: "Test Location"
    fill_in I18n.t("forms.inspection.fields.inspection_date"),
      with: Date.current.strftime("%Y-%m-%d")
    fill_in I18n.t("forms.inspection.fields.width"), with: "5.5"
    fill_in I18n.t("forms.inspection.fields.length"), with: "6.0"
    fill_in I18n.t("forms.inspection.fields.height"), with: "4.5"

    within_fieldset I18n.t("forms.inspection.sections.unit_configuration") do
      choose_yes_no(I18n.t("forms.inspection.fields.has_slide"), false)
      choose_yes_no(I18n.t("forms.inspection.fields.is_totally_enclosed"), false)
      choose_yes_no(I18n.t("forms.inspection.fields.indoor_only"), false)
    end
  end
end
