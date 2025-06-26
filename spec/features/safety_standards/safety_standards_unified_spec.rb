require "rails_helper"

RSpec.describe "Safety Standards Unified Tests" do
  shared_context "safety standards test data" do
    let(:anchor_params) do
      {
        type: "anchors",
        length: 5.0,
        width: 5.0,
        height: 3.0
      }
    end

    let(:capacity_params) do
      {
        type: "user_capacity",
        length: 5.0,
        width: 4.0,
        negative_adjustment: 2.0
      }
    end

    let(:runout_params) do
      {
        type: "slide_runout",
        platform_height: 2.5
      }
    end

    let(:wall_height_params) do
      {
        type: "wall_height",
        user_height: 1.5
      }
    end
  end

  describe "POST requests (non-JS)", type: :request do
    include_context "safety standards test data"

    describe "HTML format" do
      context "anchor calculation" do
        it "redirects with calculation params" do
          post safety_standards_path, params: {calculation: anchor_params}
          expect(response).to redirect_to(safety_standards_path(calculation: anchor_params))
        end

        it "returns error for invalid input" do
          invalid_params = anchor_params.merge(length: 0, width: 0, height: 0)
          post safety_standards_path, params: {calculation: invalid_params}

          follow_redirect!
          expect(response.body).to include('class="error"')
          expect(response.body).to include(I18n.t("safety_standards.errors.invalid_dimensions"))
        end
      end
    end

    describe "JSON format" do
      it "accepts and processes JSON requests" do
        post safety_standards_path,
          params: {calculation: anchor_params}.to_json,
          headers: {"Content-Type": "application/json", Accept: "application/json"}

        expect(response).to be_successful
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json["passed"]).to be true
        expect(json["status"]).to eq("Calculation completed successfully")
        expect(json["result"]["value"]).to eq(8)
      end

      it "returns passed: false with status for invalid input" do
        invalid_params = anchor_params.merge(length: 0, width: 0, height: 0)
        post safety_standards_path,
          params: {calculation: invalid_params}.to_json,
          headers: {"Content-Type": "application/json", Accept: "application/json"}

        json = JSON.parse(response.body)
        expect(json["passed"]).to be false
        expect(json["status"]).to eq(I18n.t("safety_standards.errors.invalid_dimensions"))
        expect(json["result"]).to be_nil
      end

      it "returns passed: false for invalid calculation type" do
        post safety_standards_path,
          params: {calculation: {type: "invalid_type", value: 123}}.to_json,
          headers: {"Content-Type": "application/json", Accept: "application/json"}

        json = JSON.parse(response.body)
        expect(json["passed"]).to be false
        expect(json["status"]).to include("Invalid calculation type")
        expect(json["result"]).to be_nil
      end
    end

    describe "Turbo Stream format" do
      let(:turbo_headers) { {Accept: "text/vnd.turbo-stream.html"} }

      context "anchor calculation" do
        it "returns turbo stream response" do
          post safety_standards_path, params: {calculation: anchor_params}, headers: turbo_headers
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("turbo-stream")
          expect(response.body).to include("anchors-result")
        end
      end
    end
  end

  describe "JavaScript behavior", type: :feature, js: true do
    include_context "safety standards test data"

    before { visit safety_standards_path }

    describe "anchor calculator" do
      it "submits via Turbo without page reload" do
        within_form("safety_standards_anchors") do
          fill_in_form("safety_standards_anchors", :length, 5.0)
          fill_in_form("safety_standards_anchors", :width, 5.0)
          fill_in_form("safety_standards_anchors", :height, 3.0)
          submit_form("safety_standards_anchors")
        end

        within("#anchors-result") do
          expect(page).to have_content("Required Anchors: 8")
        end

        expect(page).to have_current_path(safety_standards_path)
      end
    end
  end

  describe "GET requests", type: :request do
    include_context "safety standards test data"

    it "renders the page with calculation params" do
      get safety_standards_path, params: {calculation: anchor_params}
      expect(response).to be_successful
      expect(response.body).to include("Safety Standards Reference")
    end

    it "handles missing calculation params" do
      get safety_standards_path
      expect(response).to be_successful
      expect(response.body).to include("Safety Standards Reference")
    end
  end
end
