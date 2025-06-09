require "rails_helper"

RSpec.describe "Unit JSON inspection history", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  describe "GET /u/:id.json with inspection history" do
    context "when unit has completed inspections" do
      let!(:inspection1) { create(:inspection, :completed, user: user, unit: unit, passed: true, inspection_date: 3.days.ago) }
      let!(:inspection2) { create(:inspection, :completed, user: user, unit: unit, passed: false, inspection_date: 1.day.ago) }
      let!(:draft_inspection) { create(:inspection, user: user, unit: unit, complete_date: nil) }

      it "includes inspection history with correct data" do
        get "/u/#{unit.id}.json"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check inspection history is present
        expect(json["inspection_history"]).to be_present
        expect(json["inspection_history"]).to be_an(Array)
        expect(json["inspection_history"].length).to eq(2), "Expected 2 completed inspections in history"

        # Check total inspections
        expect(json["total_inspections"]).to eq(2)

        # Check last inspection details (should be the most recent by inspection_date)
        expect(json["last_inspection_date"]).to eq(inspection2.inspection_date.as_json)
        expect(json["last_inspection_passed"]).to eq(false)

        # Check inspection history order and content
        first_in_history = json["inspection_history"].first
        expect(first_in_history).not_to have_key("id")
        expect(first_in_history["inspection_date"]).to eq(inspection2.inspection_date.as_json)
        expect(first_in_history["passed"]).to eq(false)

        second_in_history = json["inspection_history"].second
        expect(second_in_history).not_to have_key("id")
        expect(second_in_history["inspection_date"]).to eq(inspection1.inspection_date.as_json)
        expect(second_in_history["passed"]).to eq(true)
      end
    end

    context "when unit has no completed inspections" do
      let!(:draft_inspection) { create(:inspection, user: user, unit: unit, complete_date: nil) }

      it "returns empty inspection history" do
        get "/u/#{unit.id}.json"

        json = JSON.parse(response.body)

        # Should not include inspection history fields at all
        expect(json).not_to have_key("inspection_history")
        expect(json).not_to have_key("total_inspections")
        expect(json).not_to have_key("last_inspection_date")
        expect(json).not_to have_key("last_inspection_passed")
      end
    end

    context "when unit has no inspections at all" do
      it "returns no inspection history fields" do
        get "/u/#{unit.id}.json"

        json = JSON.parse(response.body)

        expect(json).not_to have_key("inspection_history")
        expect(json).not_to have_key("total_inspections")
        expect(json).not_to have_key("last_inspection_date")
        expect(json).not_to have_key("last_inspection_passed")
      end
    end
  end

  describe "database query behavior" do
    let!(:inspection) { create(:inspection, :completed, user: user, unit: unit, passed: true) }

    it "properly loads inspection associations" do
      # Test that associations are properly loaded
      unit_with_inspections = Unit.includes(:inspections).find(unit.id)

      expect(unit_with_inspections.inspections).to be_loaded
      expect(unit_with_inspections.inspections.count).to eq(1)
      expect(unit_with_inspections.inspections.first.status).to eq("complete")
    end

    it "returns correct data when called directly on model" do
      # Test the serializer directly
      json = JsonSerializerService.serialize_unit(unit.reload)

      expect(json[:inspection_history]).to be_present
      expect(json[:inspection_history].length).to eq(1)
      expect(json[:last_inspection_passed]).to eq(true)
    end
  end
end
