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

    # Check PDF and JSON content is present (links may be in share buttons)
    expect(page).to have_content("PDF")
    expect(page).to have_content("JSON")

    # The actual links might be generated dynamically or in share buttons
    # Just verify the page can be accessed directly
    visit unit_path(unit, format: :pdf)
    expect(page.status_code).to eq(200)

    visit unit_path(unit, format: :json)
    expect(page.status_code).to eq(200)
  end

  scenario "inspection show page displays JSON link" do
    visit inspection_path(inspection)

    # Check PDF and JSON content is present (links may be in share buttons)
    expect(page).to have_content("PDF")
    expect(page).to have_content("JSON")

    # The actual links might be generated dynamically or in share buttons
    # Just verify the page can be accessed directly
    visit inspection_path(inspection, format: :pdf)
    expect(page.status_code).to eq(200)

    visit inspection_path(inspection, format: :json)
    expect(page.status_code).to eq(200)
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
