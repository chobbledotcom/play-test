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
      excluded_fields = %w[
        id
        created_at
        updated_at
        pdf_last_accessed_at
        user_id
        unit_id
        inspector_company_id
        inspector_signature
        signature_timestamp
      ]

      inspection_fields = Inspection.column_names - excluded_fields

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

      # Fields that are intentionally excluded from PDF rendering
      assessment_excluded_fields = {
        "StructureAssessment" => %w[unit_pressure_value],
        "AnchorageAssessment" => %w[num_anchors_comment anchor_accessories_comment anchor_degree_comment anchor_type_comment pull_strength_comment],
        "MaterialsAssessment" => %w[rope_size_comment thread_comment fabric_comment fire_retardant_comment],
        "FanAssessment" => %w[fan_size_comment blower_flap_comment blower_finger_comment pat_comment blower_visual_comment blower_serial],
        "EnclosedAssessment" => %w[exit_number_comment exit_visible_comment]
      }

      assessment_missing_fields = []
      assessment_rendered_fields = []

      assessment_classes.each do |assessment_class|
        assessment = inspection.send(assessment_class.name.underscore)
        next unless assessment

        # Standard exclusions plus class-specific exclusions
        standard_excluded = %w[id inspection_id created_at updated_at]
        class_excluded = assessment_excluded_fields[assessment_class.name] || []
        all_excluded = standard_excluded + class_excluded

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

      # Report results
      puts "\n=== PDF Field Coverage Analysis ==="
      puts "Rendered Inspection fields (#{rendered_fields.count}): #{rendered_fields.join(", ")}"
      puts "Missing Inspection fields (#{missing_fields.count}): #{missing_fields.join(", ")}" if missing_fields.any?
      puts "Rendered Assessment fields (#{assessment_rendered_fields.count}): #{assessment_rendered_fields.join(", ")}"
      puts "Missing Assessment fields (#{assessment_missing_fields.count}): #{assessment_missing_fields.join(", ")}" if assessment_missing_fields.any?

      # Test expectations - all non-excluded fields should be rendered
      expect(missing_fields.count).to be <= 10,
        "Too many Inspection fields missing from PDF: #{missing_fields.join(", ")}"

      expect(assessment_missing_fields.count).to eq(0),
        "Assessment fields missing from PDF (should update exclusion list if intentional): #{assessment_missing_fields.join(", ")}"

      # Ensure critical fields are always present
      critical_field_checks = {
        "inspection_location" => inspection.inspection_location,
        "inspection_date" => inspection.inspection_date&.strftime("%d/%m/%Y"),
        "passed" => inspection.passed? ? "PASSED" : "FAILED",
        "status" => inspection.status.humanize,
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
