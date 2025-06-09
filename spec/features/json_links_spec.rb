require "rails_helper"

RSpec.feature "JSON Links", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    sign_in(user)
  end

  scenario "unit show page displays JSON link" do
    visit unit_path(unit)

    # Check PDF link is present
    expect(page).to have_content(I18n.t("units.headers.report_link"))
    expect(page).to have_link(short_unit_report_url(unit), href: short_unit_report_url(unit))

    # Check JSON link is present
    expect(page).to have_content(I18n.t("units.headers.report_json_link"))
    expect(page).to have_link(short_unit_report_url(unit) + ".json", href: short_unit_report_url(unit) + ".json")
  end

  scenario "inspection show page displays JSON link" do
    visit inspection_path(inspection)

    # Check PDF link is present
    expect(page).to have_content(I18n.t("inspections.headers.report_pdf_link"))
    expect(page).to have_link(short_report_url(inspection), href: short_report_url(inspection))

    # Check JSON link is present
    expect(page).to have_content(I18n.t("inspections.headers.report_json_link"))
    expect(page).to have_link(short_report_url(inspection) + ".json", href: short_report_url(inspection) + ".json")
  end

  scenario "JSON links return valid JSON data" do
    # Test unit JSON link
    visit short_unit_report_url(unit) + ".json"

    json = JSON.parse(page.body)
    expect(json["name"]).to eq(unit.name)
    expect(json["serial"]).to eq(unit.serial)

    # Test inspection JSON link
    visit short_report_url(inspection) + ".json"

    json = JSON.parse(page.body)
    expect(json["inspection_location"]).to eq(inspection.inspection_location)
    expect(json["passed"]).to eq(inspection.passed)
  end
end
