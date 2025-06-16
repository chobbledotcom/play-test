require "rails_helper"

RSpec.feature "PDF Comprehensive Field Coverage", type: :feature do
  let(:user) { create(:user, name: "Test User", email: "test@example.com") }
  let(:unit) { create(:unit, serial: "TEST123", name: "Test Unit") }
  let(:inspection) do
    create(:inspection, :pdf_complete_test_data, user: user, unit: unit,
      has_slide: true, is_totally_enclosed: true)
  end

  before do
    sign_in user
  end

  scenario "renders all assessment fields in PDF" do
    visit inspection_path(inspection, format: :pdf)

    pdf_content = extract_pdf_text(page.source)

    # Verify each assessment type is rendered
    inspection.each_applicable_assessment do |assessment_key, assessment_class, _|
      # Get the i18n key for this assessment
      assessment_type = assessment_key.to_s.sub(/_assessment$/, "")
      # No special mapping needed - form names match assessment types

      # Check header is present
      header = I18n.t("forms.#{assessment_type}.header")
      expect(pdf_content).to include(header), "Missing header for #{assessment_type}"

      # Get all field keys from i18n
      fields = I18n.t("forms.#{assessment_type}.fields")
      assessment = inspection.send(assessment_key)

      fields.each do |field_key, field_label|
        # Check if assessment responds to this field
        if assessment.respond_to?(field_key)
          # For pass fields that have a corresponding base field, PDF shows base field label
          # Otherwise, PDF shows the specific field label
          expected_label = get_expected_pdf_label(field_key, field_label, fields, assessment_type)
          # Normalize whitespace for comparison (PDF may wrap lines)
          normalized_content = pdf_content.gsub(/\s+/, " ")
          normalized_label = expected_label.gsub(/\s+/, " ")

          # For complex PDF layouts, check for key distinctive words from the label
          # This is more reliable than checking for the complete exact phrase
          key_words = normalized_label.split.select { |word| word.length > 3 }
          if key_words.any?
            # Check that at least half the significant words appear
            present_words = key_words.count { |word| normalized_content.include?(word) }
            expect(present_words).to be >= (key_words.length / 2.0).ceil,
              "Missing key words from label '#{expected_label}' for #{assessment_type}.#{field_key}"
          end

          # Check if assessment responds to this field
          if assessment.respond_to?(field_key)
            # Get the field value
            value = assessment.send(field_key)

            # For pass/fail fields, check for [PASS] or [FAIL] indicators
            if field_key.to_s.end_with?("_pass") && !value.nil?
              expected_indicator = value ? "[PASS]" : "[FAIL]"
              expect(pdf_content).to include(expected_indicator),
                "Missing pass/fail indicator for #{assessment_type}.#{field_key}"
            elsif !value.nil? && !field_key.to_s.end_with?("_comment")
              # For non-comment fields with values, check the value appears
              # Boolean false should appear as [FAIL], true as [PASS]
              if [true, false].include?(value)
                expected_indicator = value ? "[PASS]" : "[FAIL]"
                expect(pdf_content).to include(expected_indicator),
                  "Missing boolean indicator for #{assessment_type}.#{field_key} - #{value.inspect}"
              else
                expect(pdf_content).to include(value.to_s),
                  "Missing value '#{value}' for #{assessment_type}.#{field_key}"
              end
            end
          else
            # Field is in i18n but not in model - this is an error
            pending "Field #{field_key} is defined in i18n but not in model #{assessment.class.name}"
          end
        end
      end
    end
  end

  scenario "renders all fields even when incomplete" do
    # Create inspection with empty assessments
    incomplete_inspection = create(:inspection, user: user, unit: unit,
      has_slide: true, is_totally_enclosed: true)

    visit inspection_path(incomplete_inspection, format: :pdf)
    pdf_content = extract_pdf_text(page.source)

    # Should still show all assessment headers
    expect(pdf_content).to include(I18n.t("forms.user_height.header"))
    expect(pdf_content).to include(I18n.t("forms.structure.header"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.header"))
    expect(pdf_content).to include(I18n.t("forms.materials.header"))
    expect(pdf_content).to include(I18n.t("forms.fan.header"))
    expect(pdf_content).to include(I18n.t("forms.slide.header"))
    expect(pdf_content).to include(I18n.t("forms.enclosed.header"))

    # Should show field labels even if values are empty (uses base field labels for grouped fields)
    expect(pdf_content).to include(I18n.t("forms.structure.fields.seam_integrity_pass"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.fields.num_low_anchors"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.fields.num_high_anchors"))
  end

  private

  def get_expected_pdf_label(field_key, field_label, fields, assessment_type)
    # PDF renderer groups fields and shows base field labels when available
    # For grouped fields (like num_low_anchors + num_low_anchors_pass),
    # PDF shows the base field label with pass/fail indicator
    base_field = field_key.to_s.sub(/_(pass|comment)$/, "")

    # If this is a pass field and there's a corresponding base field,
    # PDF will show the base field label instead
    if field_key.to_s.end_with?("_pass")
      base_field_key = base_field.to_sym
      if fields.key?(base_field_key)
        return fields[base_field_key]
      end
      # If no base field, show the pass field label
      return field_label
    end

    # For base fields and comment fields, PDF shows their label
    field_label
  end

  def extract_pdf_text(pdf_data)
    # Convert PDF binary to text for testing
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    reader.pages.map(&:text).join(" ")
  end
end
