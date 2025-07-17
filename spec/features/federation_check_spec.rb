require "rails_helper"

RSpec.describe "Federation check", type: :request do
  let(:inspection) { create(:inspection) }
  let(:unit) { create(:unit) }

  it "inspection check returns 200 when exists" do
    head "/inspections/#{inspection.id}", headers: {
      "Origin" => "https://example.com"
    }

    expect(response.status).to eq(200)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
  end

  it "inspection check returns 404 when not exists" do
    head "/inspections/NOTEXIST", headers: {
      "Origin" => "https://example.com"
    }

    expect(response.status).to eq(404)
  end

  it "unit check returns 200 when exists" do
    head "/units/#{unit.id}", headers: {
      "Origin" => "https://example.com"
    }

    expect(response.status).to eq(200)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
  end

  it "unit check returns 404 when not exists" do
    head "/units/NOTEXIST", headers: {
      "Origin" => "https://example.com"
    }

    expect(response.status).to eq(404)
  end

  it "regular JSON GET request returns full data without CORS headers" do
    get "/inspections/#{inspection.id}.json"

    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    # JSON response includes inspection data but not the ID
    expect(json.keys).to include("inspection_date", "inspector", "assessments")
    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end
end
