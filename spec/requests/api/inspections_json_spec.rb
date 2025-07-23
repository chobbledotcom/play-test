require "rails_helper"

RSpec.describe "Inspection JSON endpoints", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit, has_slide: true, is_totally_enclosed: true) }

  describe "GET /inspections/:id.json" do
    context "when inspection exists" do
      it "returns inspection data as JSON" do
        json = get_inspection_json(inspection)

        # Check specific field values
        nice_date = inspection.inspection_date.strftime("%F") # YYYY-MM-DD
        expect(json["inspection_date"]).to eq(nice_date)
        expect(json["passed"]).to eq(inspection.passed)
        expect(json["complete"]).to eq(inspection.complete?)

        # Check URLs are included
        expect(json["urls"]).to be_present
        expect(json["urls"]["report_pdf"]).to include("/inspections/#{inspection.id}.pdf")
        expect(json["urls"]["report_json"]).to include("/inspections/#{inspection.id}.json")
        expect(json["urls"]["qr_code"]).to include("/inspections/#{inspection.id}.png")
      end

      it "includes inspector company info" do
        get "/inspections/#{inspection.id}.json"

        user = inspection.user
        result = JSON.parse(response.body)&.dig("inspector")

        expect(result).to be_present
        expect(result["name"]).to eq(user.name)
        expect(result["rpii_inspector_number"]).to eq(user.rpii_inspector_number)
      end

      it "includes unit info" do
        get "/inspections/#{inspection.id}.json"

        json = JSON.parse(response.body)

        expect(json["unit"]).to be_present
        expect(json["unit"]["id"]).to eq(unit.id)
        expect(json["unit"]["name"]).to eq(unit.name)
      end

      context "with assessments" do
        let(:inspection) { create(:inspection, :completed) }

        it "includes assessment data" do
          get "/inspections/#{inspection.id}.json"

          json = JSON.parse(response.body)

          expect(json["assessments"]).to be_present
          expect(json["assessments"]["user_height_assessment"]).to be_present
          expect(json["assessments"]["structure_assessment"]).to be_present
          expect(json["assessments"]["slide_assessment"]).to be_present
          expect(json["assessments"]["enclosed_assessment"]).to be_present

          # Check assessment fields
          user_height = json["assessments"]["user_height_assessment"]
          expect(user_height["containing_wall_height"]).to be_present
          expect(user_height["platform_height"]).to be_present
          expect(user_height).not_to have_key("inspection_id")
          expect(user_height).not_to have_key("created_at")
        end

        it "includes all assessment fields except system fields" do
          # Use complete inspection that already has all assessments
          complete_inspection = create(:inspection, :completed, user: user, unit: unit)

          json = get_inspection_json(complete_inspection)

          # Check specific fields are included using helper
          expect_assessment_json(json, "anchorage_assessment",
            %w[num_low_anchors_comment num_high_anchors_comment anchor_accessories_comment])

          expect_assessment_json(json, "materials_assessment",
            %w[ropes_comment thread_comment])

          expect_assessment_json(json, "fan_assessment",
            %w[blower_serial pat_comment])
        end
      end

      context "when unit doesn't have slide" do
        it "excludes slide assessment even if present" do
          inspection = create(:inspection, :completed, has_slide: false)

          # Slide assessment already exists from inspection creation
          inspection.slide_assessment.update!(runout: 2.5)

          get inspection_path(inspection, format: :json)

          json = JSON.parse(response.body)

          if json["assessments"]
            expect(json["assessments"]).not_to have_key("slide_assessment")
          end
        end
      end
    end

    context "when inspection does not exist" do
      it "returns 404" do
        get "/inspections/NONEXISTENT.json"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "using long URL format" do
      it "returns JSON for /inspections/:id.json" do
        get "/inspections/#{inspection.id}.json"

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")

        JSON.parse(response.body)
      end
    end
  end
end
