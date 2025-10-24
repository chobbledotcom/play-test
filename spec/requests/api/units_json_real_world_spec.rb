# typed: false

require "rails_helper"

RSpec.describe "Unit JSON real-world scenarios", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  describe "GET /u/:id.json" do
    context "with existing completed inspections in database" do
      before do
        # Create inspections before making the request
        @inspection1 = create(:inspection, :completed,
          user: user,
          unit: unit,
          inspection_date: 3.days.ago)

        @inspection2 = create(:inspection, :completed,
          user: user,
          unit: unit,
          passed: false,
          inspection_date: 1.day.ago)

        # Also create a draft inspection that should NOT appear
        @draft = create(:inspection,
          user: user,
          unit: unit)
      end

      it "returns inspection history data" do
        # Make the request
        get "/units/#{unit.id}.json"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Basic unit data should be present
        expect(json["name"]).to eq(unit.name)
        expect(json["serial"]).to eq(unit.serial)

        # Inspection history should be present
        expect(json).to have_key("inspection_history")
        expect(json["inspection_history"]).to be_an(Array)
        expect(json["inspection_history"].length).to eq(2), "Should have 2 completed inspections"

        # Check summary fields
        expect(json["total_inspections"]).to eq(2)
        expect(json["last_inspection_date"]).not_to be_nil
        expect(json["last_inspection_passed"]).to eq(false), "Most recent inspection failed"

        # Verify the order (most recent first)
        first = json["inspection_history"][0]
        expect(first["passed"]).to eq(false)

        second = json["inspection_history"][1]
        expect(second["passed"]).to eq(true)
      end
    end

    context "mimicking the exact controller flow" do
      it "works like the actual controller" do
        # Create inspection
        create(:inspection, :completed, user: user, unit: unit, passed: true)

        # Simulate what the controller does
        found_unit = Unit.find_by(id: unit.id.upcase)
        expect(found_unit).to eq(unit)

        # Now test through the actual endpoint
        get "/units/#{unit.id}.json"
        response_json = JSON.parse(response.body)
        expect(response_json["inspection_history"]).to be_present
      end
    end
  end
end
