require "rails_helper"

RSpec.feature "Federation check", type: :feature do
  let(:inspection) { create(:inspection) }
  let(:unit) { create(:unit) }

  scenario "inspection check returns 200 when exists" do
    page.driver.header "Origin", "https://example.com"
    page.driver.get "/inspections/#{inspection.id}.json?check=true"

    expect(page.status_code).to eq(200)
    expect(page.response_headers["Access-Control-Allow-Origin"]).to eq("*")
  end

  scenario "inspection check returns 404 when not exists" do
    page.driver.header "Origin", "https://example.com"
    page.driver.get "/inspections/NOTEXIST.json?check=true"

    expect(page.status_code).to eq(404)
  end

  scenario "unit check returns 200 when exists" do
    page.driver.header "Origin", "https://example.com"
    page.driver.get "/units/#{unit.id}.json?check=true"

    expect(page.status_code).to eq(200)
    expect(page.response_headers["Access-Control-Allow-Origin"]).to eq("*")
  end

  scenario "unit check returns 404 when not exists" do
    page.driver.header "Origin", "https://example.com"
    page.driver.get "/units/NOTEXIST.json?check=true"

    expect(page.status_code).to eq(404)
  end

  scenario "regular JSON request without check param returns full data" do
    page.driver.get "/inspections/#{inspection.id}.json"

    expect(page.status_code).to eq(200)
    json = JSON.parse(page.body)
    # JSON response includes inspection data but not the ID
    expect(json.keys).to include("inspection_date", "inspector", "assessments")
    expect(page.response_headers["Access-Control-Allow-Origin"]).to be_nil
  end
end
