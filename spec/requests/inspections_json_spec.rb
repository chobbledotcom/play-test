require "rails_helper"

RSpec.describe "Inspection JSON endpoints", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, has_slide: true, is_totally_enclosed: true) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  describe "GET /r/:id.json" do
    context "when inspection exists" do
      it "returns inspection data as JSON" do
        get "/r/#{inspection.id}.json"

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)

        # Check basic fields are included
        expect(json["inspection_date"]).to eq(inspection.inspection_date.as_json)
        expect(json["inspection_location"]).to eq(inspection.inspection_location)
        expect(json["passed"]).to eq(inspection.passed)
        expect(json["complete"]).to eq(inspection.complete?)
        expect(json["comments"]).to eq(inspection.comments)

        # Check sensitive fields are excluded
        expect(json).not_to have_key("user_id")
        expect(json).not_to have_key("inspector_signature")
        expect(json).not_to have_key("signature_timestamp")
        expect(json).not_to have_key("created_at")
        expect(json).not_to have_key("updated_at")

        # Check URLs are included
        expect(json["urls"]).to be_present
        expect(json["urls"]["report_pdf"]).to include("/r/#{inspection.id}")
        expect(json["urls"]["report_json"]).to include("/r/#{inspection.id}.json")
        expect(json["urls"]["qr_code"]).to include("/inspections/#{inspection.id}/qr_code")
      end

      it "includes inspector company info" do
        get "/r/#{inspection.id}.json"

        json = JSON.parse(response.body)

        expect(json["inspector_company"]).to be_present
        expect(json["inspector_company"]["name"]).to eq(inspection.inspector_company.name)
        expect(json["inspector_company"]["rpii_registration_number"]).to eq(inspection.inspector_company.rpii_registration_number)
      end

      it "includes unit info" do
        get "/r/#{inspection.id}.json"

        json = JSON.parse(response.body)

        expect(json["unit"]).to be_present
        expect(json["unit"]["id"]).to eq(unit.id)
        expect(json["unit"]["name"]).to eq(unit.name)
        expect(json["unit"]["has_slide"]).to eq(true)
        expect(json["unit"]["is_totally_enclosed"]).to eq(true)
      end

      context "with assessments" do
        let!(:user_height_assessment) { create(:user_height_assessment, :complete, inspection: inspection) }
        let!(:structure_assessment) { create(:structure_assessment, :complete, inspection: inspection) }
        let!(:slide_assessment) { create(:slide_assessment, :complete, inspection: inspection) }
        let!(:enclosed_assessment) { create(:enclosed_assessment, :passed, inspection: inspection) }

        it "includes assessment data" do
          get "/r/#{inspection.id}.json"

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
          create(:anchorage_assessment, :complete, inspection: inspection)
          create(:materials_assessment, :complete, inspection: inspection)
          create(:fan_assessment, :complete, inspection: inspection)

          get "/r/#{inspection.id}.json"

          json = JSON.parse(response.body)

          # Check AnchorageAssessment includes all fields
          anchorage = json["assessments"]["anchorage_assessment"]
          expect(anchorage).to have_key("num_anchors_comment")
          expect(anchorage).to have_key("anchor_accessories_comment")

          # Check MaterialsAssessment includes all fields
          materials = json["assessments"]["materials_assessment"]
          expect(materials).to have_key("rope_size_comment")
          expect(materials).to have_key("thread_comment")

          # Check FanAssessment includes all fields
          fan = json["assessments"]["fan_assessment"]
          expect(fan).to have_key("blower_serial")
          expect(fan).to have_key("pat_comment")
        end
      end

      context "when unit doesn't have slide" do
        let(:unit_no_slide) { create(:unit, user: user, has_slide: false) }
        let(:inspection_no_slide) { create(:inspection, :completed, user: user, unit: unit_no_slide) }

        it "excludes slide assessment even if present" do
          create(:slide_assessment, inspection: inspection_no_slide)

          get "/r/#{inspection_no_slide.id}.json"

          json = JSON.parse(response.body)

          if json["assessments"]
            expect(json["assessments"]).not_to have_key("slide_assessment")
          end
        end
      end
    end

    context "when inspection does not exist" do
      it "returns 404" do
        get "/r/NONEXISTENT.json"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "using long URL format" do
      it "returns JSON for /inspections/:id/report.json" do
        get "/inspections/#{inspection.id}/report.json"

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json["inspection_location"]).to eq(inspection.inspection_location)
      end
    end
  end

  describe "field coverage using reflection" do
    it "includes all inspection fields except excluded ones" do
      get "/r/#{inspection.id}.json"

      json = JSON.parse(response.body)

      # Get expected fields using same reflection as service
      excluded_fields = %w[
        id created_at updated_at pdf_last_accessed_at
        user_id unit_id inspector_company_id
        inspector_signature signature_timestamp
      ]
      expected_fields = Inspection.column_names - excluded_fields

      # Check all expected fields are present (if they have values)
      expected_fields.each do |field|
        value = inspection.send(field)
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
