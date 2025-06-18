require "rails_helper"

RSpec.feature "Inspection Prefilling", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before { sign_in(user) }

  scenario "prefills fields from previous inspection" do
    create(:inspection, :completed,
      user: user,
      inspection_date: 365.days.ago,
      unit: unit,
      width: 55555)

    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    expect(page).to have_content(I18n.t("inspections.titles.edit"))

    new_inspection = unit.inspections.order(:inspection_date).last
    expect(new_inspection.width).to eq(nil)
    expect(page).to have_current_path(edit_inspection_path(new_inspection))

    location_field = find_form_field(:inspection, :inspection_location)
    expect(location_field.value).to eq("Test Location")

    field_wrapper = location_field.find(:xpath, "..")
    expect(field_wrapper[:class]).to include("set-previous")

    width_field = find_form_field(:inspection, :width)
    expect(width_field.value).to eq("55555")

    click_button I18n.t("forms.inspection.submit")
    expect_updated_message

    visit edit_inspection_path(new_inspection)
    width_field = find_form_field(:inspection, :width)
    expect(width_field.value).to eq("55555.0")

    location_field = find_form_field(:inspection, :inspection_location)
    field_wrapper = location_field.find(:xpath, "..")
    expect(field_wrapper[:class]).not_to include("set-previous")
  end
end
