require "rails_helper"

RSpec.feature "PDF Comprehensive Field Coverage", type: :feature do
  let(:user) { create(:user, name: "Test User", email: "test@example.com") }
  let(:unit) { create(:unit, serial: "TEST123", name: "Test Unit") }
  let(:inspection) { create(:inspection, :completed, user:, unit:) }

  before do
    sign_in user
  end

  scenario "renders all assessment fields in PDF" do
    visit inspection_path(inspection, format: :pdf)

    pdf_content = extract_pdf_text(page.source)

    inspection.each_applicable_assessment do |assessment_key, assessment_class, _|
      assessment_type = assessment_key.to_s.sub(/_assessment$/, "")

      header = I18n.t("forms.#{assessment_type}.header")
      expect(pdf_content).to include(header), "Missing header for #{assessment_type}"

      fields = I18n.t("forms.#{assessment_type}.fields")
      assessment = inspection.send(assessment_key)

      fields.each do |field_key, field_label|
        if assessment.respond_to?(field_key)

          expected_label = get_expected_pdf_label(field_key, field_label, fields, assessment_type)

          normalized_content = pdf_content.gsub(/\s+/, " ")
          normalized_label = expected_label.gsub(/\s+/, " ")

          key_words = normalized_label.split.select { |word| word.length > 3 }
          if key_words.any?

            present_words = key_words.count { |word| normalized_content.include?(word) }
            expect(present_words).to be >= (key_words.length / 2.0).ceil,
              "Missing key words from label '#{expected_label}' for #{assessment_type}.#{field_key}"
          end

          if assessment.respond_to?(field_key)

            value = assessment.send(field_key)

            if field_key.to_s.end_with?("_pass") && !value.nil?
              expected_indicator = value ? "[PASS]" : "[FAIL]"
              expect(pdf_content).to include(expected_indicator),
                "Missing pass/fail indicator for #{assessment_type}.#{field_key}"
            elsif !value.nil? && !field_key.to_s.end_with?("_comment")

              if [true, false].include?(value) && !field_key.to_s.end_with?("_pass")
                expected_value = value ? "Yes" : "No"
                expect(pdf_content).to include(expected_value),
                  "Missing boolean value for #{assessment_type}.#{field_key} - expected '#{expected_value}'"
              elsif [true, false].include?(value)
                expected_indicator = value ? "[PASS]" : "[FAIL]"
                expect(pdf_content).to include(expected_indicator),
                  "Missing boolean indicator for #{assessment_type}.#{field_key} - #{value.inspect}"
              else
                expect(pdf_content).to include(value.to_s),
                  "Missing value '#{value}' for #{assessment_type}.#{field_key}"
              end
            end
          else

            pending "Field #{field_key} is defined in i18n but not in model #{assessment.class.name}"
          end
        end
      end
    end
  end

  scenario "renders all fields even when incomplete" do
    incomplete_inspection = create(:inspection, user: user, unit: unit,
      has_slide: true, is_totally_enclosed: true)

    visit inspection_path(incomplete_inspection, format: :pdf)
    pdf_content = extract_pdf_text(page.source)

    expect(pdf_content).to include(I18n.t("forms.user_height.header"))
    expect(pdf_content).to include(I18n.t("forms.structure.header"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.header"))
    expect(pdf_content).to include(I18n.t("forms.materials.header"))
    expect(pdf_content).to include(I18n.t("forms.fan.header"))
    expect(pdf_content).to include(I18n.t("forms.slide.header"))
    expect(pdf_content).to include(I18n.t("forms.enclosed.header"))

    expect(pdf_content).to include(I18n.t("forms.structure.fields.seam_integrity_pass"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.fields.num_low_anchors"))
    expect(pdf_content).to include(I18n.t("forms.anchorage.fields.num_high_anchors"))
  end

  private

  def get_expected_pdf_label(field_key, field_label, fields, assessment_type)
    base_field = field_key.to_s.sub(/_(pass|comment)$/, "")

    if field_key.to_s.end_with?("_pass")
      base_field_key = base_field.to_sym
      if fields.key?(base_field_key)
        return fields[base_field_key]
      end

      return field_label
    end

    field_label
  end

  def extract_pdf_text(pdf_data)
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    reader.pages.map(&:text).join(" ")
  end
end
