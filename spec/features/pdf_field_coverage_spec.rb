require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Field Coverage", type: :feature do
  let(:user) { create(:user) }
  let(:inspector_company) { user.inspection_company }
  let(:unit) do
    create(:unit,
      user: user,
      name: "Test Bouncy Castle",
      manufacturer: "Bounce Co Ltd",
      serial_number: "BCL-2024-001",
      width: 5.5,
      length: 6.0,
      height: 4.5,
      has_slide: true,
      is_totally_enclosed: true)
  end

  before do
    sign_in(user)
  end

  feature "Inspection PDF renders all relevant model fields" do
    scenario "includes all inspection model fields except system/metadata fields" do
      inspection = create(:inspection, :pdf_complete_test_data, user: user, unit: unit)

      # Create all assessment types with complete data using factories
      create(:user_height_assessment, :complete,
        inspection: inspection,
        permanent_roof: true)

      create(:structure_assessment, :complete,
        inspection: inspection,
        evacuation_time: 25.0,
        evacuation_time_pass: true)

      create(:anchorage_assessment, :complete,
        inspection: inspection)

      create(:materials_assessment, :complete,
        inspection: inspection)

      create(:fan_assessment, :complete,
        inspection: inspection)

      create(:slide_assessment, :complete,
        inspection: inspection,
        slide_permanent_roof: false)

      create(:enclosed_assessment, :passed,
        inspection: inspection)

      get(inspection_report_path(inspection))

      # Analyze PDF content
      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Get all Inspection model fields using reflection
      inspection_fields = Inspection.column_names - PublicFieldFiltering::PDF_TOTAL_EXCLUDED_FIELDS

      # Track fields that should be rendered in PDF
      missing_fields = []
      rendered_fields = []

      inspection_fields.each do |field|
        field_value = inspection.send(field)
        next if field_value.nil?

        # Convert field value to string for search
        search_value = case field_value
        when true
          "Pass"
        when false
          "Fail"
        when Numeric
          field_value.to_s
        else
          field_value.to_s
        end

        # Skip empty strings
        next if search_value.blank?

        # Check if the field value appears in the PDF
        if text_content.include?(search_value)
          rendered_fields << field
        else
          missing_fields << "#{field}: #{search_value}"
        end
      end

      # Assessment field coverage
      assessment_classes = [
        UserHeightAssessment,
        StructureAssessment,
        AnchorageAssessment,
        MaterialsAssessment,
        FanAssessment,
        SlideAssessment,
        EnclosedAssessment
      ]

      # Use shared assessment exclusions from PublicFieldFiltering

      assessment_missing_fields = []
      assessment_rendered_fields = []

      assessment_classes.each do |assessment_class|
        assessment = inspection.send(assessment_class.name.underscore)
        next unless assessment

        # Use shared exclusions
        all_excluded = PublicFieldFiltering::EXCLUDED_FIELDS + (PublicFieldFiltering::ASSESSMENT_EXCLUDED_FIELDS[assessment_class.name] || [])
        assessment_fields = assessment_class.column_names - all_excluded

        assessment_fields.each do |field|
          field_value = assessment.send(field)
          next if field_value.nil?

          search_value = case field_value
          when true
            "Pass"
          when false
            "Fail"
          when Numeric
            field_value.to_s
          else
            field_value.to_s
          end

          next if search_value.blank?

          if text_content.include?(search_value)
            assessment_rendered_fields << "#{assessment_class.name}.#{field}"
          else
            assessment_missing_fields << "#{assessment_class.name}.#{field}: #{search_value}"
          end
        end
      end

      # Test expectations - all non-excluded fields should be rendered
      expect(missing_fields.count).to be <= 0,
        "Inspection fields missing from PDF: #{missing_fields.join(", ")}"

      expect(assessment_missing_fields.count).to eq(0),
        "Assessment fields missing from PDF (should update exclusion list if intentional): #{assessment_missing_fields.join(", ")}"

      # Ensure critical fields are always present
      critical_field_checks = {
        "inspection_location" => inspection.inspection_location,
        "inspection_date" => inspection.inspection_date&.strftime("%d/%m/%Y"),
        "passed" => inspection.passed? ? "PASSED" : "FAILED",
        "status" => inspection.complete? ? "Complete" : "Draft",
        "comments" => inspection.comments
      }

      critical_field_checks.each do |field_name, expected_value|
        next if expected_value.nil?

        expect(text_content).to include(expected_value.to_s),
          "Critical field '#{field_name}' with value '#{expected_value}' not found in PDF"
      end
    end

    scenario "handles nil and empty values gracefully" do
      # Create inspection with minimal data
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: "Minimal Test Location",
        passed: true)

      # Create minimal assessments with mostly nil values
      create(:user_height_assessment, inspection: inspection)
      create(:structure_assessment, inspection: inspection)

      get(inspection_report_path(inspection))

      # Should generate PDF successfully even with minimal data
      expect(response.status).to eq(200)
      expect(response.headers["Content-Type"]).to eq("application/pdf")

      # Verify it's a valid PDF
      expect { PDF::Inspector::Text.analyze(response.body) }.not_to raise_error

      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Should include fallback text for missing data
      expect(text_content).to include("N/A")
      expect(text_content).to include("No") # for "No data available" messages
    end
  end

  private

  def get(path)
    page.driver.browser.get(path)
  end

  def response
    page.driver.response
  end

  def inspection_report_path(inspection)
    "/inspections/#{inspection.id}/report"
  end
end
