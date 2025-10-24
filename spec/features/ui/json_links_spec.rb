# typed: false

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

    expect(page).to have_content("PDF")
    expect(page).to have_content("JSON")

    visit unit_path(unit, format: :pdf)
    expect(page.status_code).to eq(200)

    visit unit_path(unit, format: :json)
    expect(page.status_code).to eq(200)
  end

  scenario "inspection show page displays JSON link" do
    visit inspection_path(inspection)

    expect(page).to have_content("PDF")
    expect(page).to have_content("JSON")

    visit inspection_path(inspection, format: :pdf)
    expect(page.status_code).to eq(200)

    visit inspection_path(inspection, format: :json)
    expect(page.status_code).to eq(200)
  end

  scenario "JSON links return valid JSON data" do
    visit unit_url(unit, format: :json)

    json = JSON.parse(page.body)
    expect(json["name"]).to eq(unit.name)
    expect(json["serial"]).to eq(unit.serial)

    visit inspection_url(inspection, format: :json)

    json = JSON.parse(page.body)
    expect(json["passed"]).to eq(inspection.passed)
  end
end
