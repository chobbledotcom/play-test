require "rails_helper"

RSpec.describe "Safety Standards API", type: :request do
  describe "POST /safety_standards" do
    context "with JSON request format" do
      let(:headers) { {"Content-Type": "application/json", Accept: "application/json"} }

      it "calculates anchor requirements" do
        post safety_standards_path,
          params: {calculation: {type: "anchors", length: 5.0, width: 5.0, height: 3.0}}.to_json,
          headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["passed"]).to be true
        expect(json_response["result"]["value"]).to eq 8
        expect(json_response["result"]["breakdown"]).to be_an(Array)
        expect(json_response["result"]["breakdown"].size).to eq 5
      end

      it "returns error for invalid data" do
        post safety_standards_path,
          params: {calculation: {type: "anchors", length: 0, width: 0, height: 0}}.to_json,
          headers: headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["passed"]).to be false
        expect(json_response["status"]).to be_present
      end
    end
  end
end
