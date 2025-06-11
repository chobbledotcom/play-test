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
    expect(page).to have_link(unit_url(unit, format: :pdf), href: unit_url(unit, format: :pdf))

    # Check JSON link is present
    expect(page).to have_content(I18n.t("units.headers.report_json_link"))
    expect(page).to have_link(unit_url(unit, format: :json), href: unit_url(unit, format: :json))
  end

  scenario "inspection show page displays JSON link" do
    visit inspection_path(inspection)

    # Check PDF link is present
    expect(page).to have_content(I18n.t("inspections.headers.report_pdf_link"))
    expect(page).to have_link(inspection_url(inspection, format: :pdf), href: inspection_url(inspection, format: :pdf))

    # Check JSON link is present
    expect(page).to have_content(I18n.t("inspections.headers.report_json_link"))
    expect(page).to have_link(inspection_url(inspection, format: :json), href: inspection_url(inspection, format: :json))
  end

  scenario "JSON links return valid JSON data" do
    # Test unit JSON link
    visit unit_url(unit, format: :json)

    json = JSON.parse(page.body)
    expect(json["name"]).to eq(unit.name)
    expect(json["serial"]).to eq(unit.serial)

    # Test inspection JSON link
    visit inspection_url(inspection, format: :json)

    json = JSON.parse(page.body)
    expect(json["inspection_location"]).to eq(inspection.inspection_location)
    expect(json["passed"]).to eq(inspection.passed)
  end
end
