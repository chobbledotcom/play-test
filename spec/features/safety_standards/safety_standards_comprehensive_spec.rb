require "rails_helper"

RSpec.describe "Safety Standards Comprehensive Tests" do
  include SafetyStandardsTestHelpers
  shared_context "calculation parameters" do
    let(:valid_anchor_params) { {length: 5.0, width: 5.0, height: 3.0} }
    let(:invalid_anchor_params) { {length: 0, width: 0, height: 0} }

    let(:valid_runout_params) { {height: 2.5} }
    let(:invalid_runout_params) { {height: 0} }

    let(:valid_wall_params) { {height: 1.5} }
    let(:invalid_wall_params) { {height: 0} }
  end

  describe "Non-JavaScript tests", type: :feature do
    include_context "calculation parameters"

    scenario "anchor calculation via GET request" do
      visit safety_standards_path(calculation: {
        type: "anchors",
        length: 5.0,
        width: 5.0,
        height: 3.0
      })

      expect_anchor_result(8)
    end

    scenario "form submission via POST (no JS)" do
      visit safety_standards_path

      fill_anchor_form(**valid_anchor_params)
      submit_anchor_form

      expect(current_url).to include("calculation")
      expect_anchor_result(8)
    end
  end

  describe "JavaScript tests", js: true, type: :feature do
    include_context "calculation parameters"

    describe "Turbo form submissions" do
      scenario "anchor calculation updates without reload" do
        visit safety_standards_path
        url_before = current_url

        fill_anchor_form(**valid_anchor_params)
        submit_anchor_form

        expect_anchor_result(8)
        expect(current_url).to eq(url_before)
      end

      scenario "runout calculation updates without reload" do
        visit safety_standards_path
        navigate_to_tab("Slides")

        fill_runout_form(**valid_runout_params)
        submit_runout_form

        expect_runout_result(required_runout: 1.25)
      end

      scenario "wall height calculation updates without reload" do
        visit safety_standards_path
        navigate_to_tab("Slides")

        fill_wall_height_form(**valid_wall_params)
        submit_wall_height_form

        expect_wall_height_result("Required Wall Height: 1.5m")
      end
    end

    describe "Form validation" do
      scenario "HTML5 validation prevents invalid values" do
        visit safety_standards_path

        # The forms have min values that prevent submitting zeros
        expect_form_field_min_value("safety_standards_anchors", "length", "1.0")
      end
    end

    describe "Multiple form interactions" do
      scenario "all forms work independently" do
        visit safety_standards_path

        # Submit anchor form
        submit_form_with_values(:anchors, valid_anchor_params)

        # Submit slide forms
        navigate_to_tab("Slides")
        submit_form_with_values(:runout, valid_runout_params)
        submit_form_with_values(:wall_height, valid_wall_params)

        # Verify all results
        navigate_to_tab("Anchorage")
        expect_anchor_result(8)

        navigate_to_tab("Slides")
        expect_runout_result(required_runout: 1.25)
        expect_wall_height_result("Required Wall Height: 1.5m")
      end

      scenario "form values persist after submission" do
        visit safety_standards_path

        fill_anchor_form(**valid_anchor_params)
        submit_anchor_form

        expect_form_values_persist("safety_standards_anchors", {
          length: "5.0",
          width: "5.0",
          height: "3.0"
        })
      end
    end
  end

  describe "API tests", type: :request do
    include_context "calculation parameters"

    def api_request(params)
      post safety_standards_path,
        params: {calculation: params}.to_json,
        headers: {"Content-Type": "application/json", Accept: "application/json"}
    end

    def turbo_request(params)
      post safety_standards_path,
        params: {calculation: params},
        headers: {Accept: "text/vnd.turbo-stream.html"}
    end

    describe "JSON API" do
      it "accepts JSON requests and returns JSON responses" do
        api_request(type: "anchors", **valid_anchor_params)

        expect(response).to be_successful
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json).to have_key("passed")
        expect(json).to have_key("status")
        expect(json).to have_key("result")
      end

      it "always includes status explanation" do
        api_request(type: "anchors", length: 0, width: 0, height: 0)

        json = JSON.parse(response.body)
        expect(json["passed"]).to be false
        expect(json["status"]).to be_present
        expect(json["status"]).not_to eq("")
      end
    end

    describe "Turbo Stream responses" do
      it "returns turbo stream for anchor calculation" do
        turbo_request(type: "anchors", **valid_anchor_params)

        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include('action="update"')
        expect(response.body).to include('target="anchors-result"')
      end

      it "returns different targets for different calculations" do
        targets = {
          "anchors" => "anchors-result",
          "slide_runout" => "slide-runout-result",
          "wall_height" => "wall-height-result"
        }

        targets.each do |type, target|
          params = case type
          when "anchors" then {type: type, **valid_anchor_params}
          when "slide_runout" then {type: type, platform_height: 2.5}
          when "wall_height" then {type: type, user_height: 1.5}
          end

          turbo_request(params)
          expect(response.body).to include(%(target="#{target}"))
        end
      end
    end
  end

  describe "POST request error handling", type: :request do
    include_context "calculation parameters"

    it "handles anchor errors via POST" do
      post safety_standards_path, params: {calculation: {type: "anchors", **invalid_anchor_params}}
      expect(response).to redirect_to(safety_standards_path(calculation: {type: "anchors", **invalid_anchor_params}))

      follow_redirect!
      expect(response.body).to include("Error:")
      expect(response.body).to include(I18n.t("safety_standards.errors.invalid_dimensions"))
    end
  end
end
