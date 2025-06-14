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
    Inspection::ASSESSMENT_TYPES.each do |assessment_name, assessment_class|
      # Skip conditional assessments if not applicable
      next if assessment_name == :slide_assessment && !inspection.has_slide?
      next if assessment_name == :enclosed_assessment && !inspection.is_totally_enclosed?
      
      # Get the i18n key for this assessment
      assessment_type = assessment_name.to_s.sub(/_assessment$/, "")
      assessment_type = "tallest_user_height" if assessment_type == "user_height"
      
      # Check header is present
      header = I18n.t("forms.#{assessment_type}.header")
      expect(pdf_content).to include(header), "Missing header for #{assessment_type}"
      
      # Get all field keys from i18n
      fields = I18n.t("forms.#{assessment_type}.fields")
      assessment = inspection.send(assessment_name)
      
      fields.each do |field_key, field_label|
        # Check if assessment responds to this field
        if assessment.respond_to?(field_key)
          # Field label should appear in PDF
          expect(pdf_content).to include(field_label), 
            "Missing field label '#{field_label}' for #{assessment_type}.#{field_key}"
          
          # Check if assessment responds to this field
          if assessment.respond_to?(field_key)
            # Get the field value
            value = assessment.send(field_key)
            
            # For pass/fail fields, check for Pass or Fail
            if field_key.to_s.end_with?("_pass") && !value.nil?
              expected_text = value ? I18n.t("shared.pass") : I18n.t("shared.fail")
              expect(pdf_content).to include(expected_text),
                "Missing pass/fail value for #{assessment_type}.#{field_key}"
            elsif !value.nil? && !field_key.to_s.end_with?("_comment")
              # For non-comment fields with values, check the value appears
              expect(pdf_content).to include(value.to_s),
                "Missing value '#{value}' for #{assessment_type}.#{field_key}"
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
    expect(pdf_content).to include(I18n.t("forms.tallest_user_height.header"))
    expect(pdf_content).to include(I18n.t("forms.structure.header"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.header"))
    expect(pdf_content).to include(I18n.t("forms.materials.header"))
    expect(pdf_content).to include(I18n.t("forms.fan.header"))
    expect(pdf_content).to include(I18n.t("forms.slide.header"))
    expect(pdf_content).to include(I18n.t("forms.enclosed.header"))
    
    # Should show field labels even if values are empty
    expect(pdf_content).to include(I18n.t("forms.structure.fields.seam_integrity_pass"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.fields.num_anchors_pass"))
  end

  private

  def extract_pdf_text(pdf_data)
    # Convert PDF binary to text for testing
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    reader.pages.map(&:text).join(" ")
  end
end