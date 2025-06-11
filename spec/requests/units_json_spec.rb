require "rails_helper"

RSpec.describe "Unit JSON endpoints", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, notes: "Private notes") }

  describe "GET /units/:id.json" do
    context "when unit exists" do
      it "returns unit data as JSON" do
        get "/units/#{unit.id}.json"

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)

        # Check basic fields are included
        expect(json["name"]).to eq(unit.name)
        expect(json["serial"]).to eq(unit.serial)
        expect(json["manufacturer"]).to eq(unit.manufacturer)
        expect(json["has_slide"]).to eq(unit.has_slide)

        # Check sensitive fields are excluded
        expect(json).not_to have_key("user_id")
        expect(json).not_to have_key("notes")
        expect(json).not_to have_key("created_at")
        expect(json).not_to have_key("updated_at")

        # Check URLs are included
        expect(json["urls"]).to be_present
        expect(json["urls"]["report_pdf"]).to include("/units/#{unit.id}.pdf")
        expect(json["urls"]["report_json"]).to include("/units/#{unit.id}.json")
        expect(json["urls"]["qr_code"]).to include("/units/#{unit.id}.png")
      end

      context "with inspection history" do
        let!(:inspection1) { create(:inspection, :completed, user: user, unit: unit, passed: true, inspection_date: 2.days.ago) }
        let!(:inspection2) { create(:inspection, :completed, user: user, unit: unit, passed: false, inspection_date: 1.day.ago) }
        let!(:draft_inspection) { create(:inspection, user: user, unit: unit, complete_date: nil) }

        it "includes completed inspection history" do
          get "/units/#{unit.id}.json"

          json = JSON.parse(response.body)

          expect(json["inspection_history"]).to be_present
          expect(json["inspection_history"].length).to eq(2) # Only completed inspections
          expect(json["total_inspections"]).to eq(2)
          expect(json["last_inspection_passed"]).to eq(false) # Most recent (by inspection_date) is failed

          # Check inspection data
          first_inspection = json["inspection_history"].first
          expect(first_inspection).not_to have_key("id")
          expect(first_inspection["passed"]).to eq(false)
          expect(first_inspection["complete"]).to eq(true)
          expect(first_inspection["inspector_company"]).to be_present
        end
      end
    end

    context "when unit does not exist" do
      it "returns 404" do
        get "/units/NONEXISTENT.json"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "using long URL format" do
      it "returns JSON for /units/:id.json" do
        get "/units/#{unit.id}.json"

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json["name"]).to eq(unit.name)
      end
    end
  end

  describe "field coverage using reflection" do
    it "includes all unit fields except excluded ones" do
      get "/units/#{unit.id}.json"

      json = JSON.parse(response.body)

      # Get expected fields using same reflection as service
      excluded_fields = %w[id created_at updated_at user_id notes]
      expected_fields = Unit.column_names - excluded_fields

      # Check all expected fields are present (if they have values)
      expected_fields.each do |field|
        value = unit.send(field)
        if value.present?
          expect(json).to have_key(field), "Expected field '#{field}' to be in JSON"
        end
      end

      # Check excluded fields are not present
      excluded_fields.each do |field|
        expect(json).not_to have_key(field), "Field '#{field}' should be excluded from JSON"
      end
    end
  end
end
