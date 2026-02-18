# typed: false
# frozen_string_literal: true

require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Complete Integration", type: :feature do
  let(:user) do
    create(:user, name: "Integration Test User", email: "test@example.com")
  end
  let(:unit) { create(:unit, :with_all_fields, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    sign_in user
  end

  scenario "generates comprehensive PDF with complete field coverage" do
    visit inspection_path(inspection, format: :pdf)

    pdf_content = extract_pdf_text(page.source)

    # Validate all assessment sections are present with i18n headers
    inspection.each_applicable_assessment do |assessment_key, _, _|
      assessment_type = assessment_key.to_s.sub(/_assessment$/, "")
      header = I18n.t("forms.#{assessment_type}.header")
      expect(pdf_content).to include(header),
        "Missing header for #{assessment_type}"

      # Validate all field labels are present
      fields = I18n.t("forms.#{assessment_type}.fields")
      assessment = inspection.send(assessment_key)

      fields.each do |field_key, field_label|
        next unless assessment.respond_to?(field_key)

        expected_label = get_expected_pdf_label(
          field_key, field_label, fields, assessment_type
        )
        normalized_content = pdf_content.gsub(/\s+/, " ")
        normalized_label = expected_label.gsub(/\s+/, " ")

        key_words = normalized_label.split.select { |word| word.length > 3 }
        if key_words.any?
          present_words = key_words.count do |word|
            normalized_content.include?(word)
          end
          expect(present_words).to be >= (key_words.length / 2.0).ceil,
            "Missing key words from label '#{expected_label}' " \
            "for #{assessment_type}.#{field_key}"
        end

        # Validate field values are properly formatted
        value = assessment.send(field_key)
        next if value.nil?

        if field_key.to_s.end_with?("_pass") && !value.nil?
          expected_indicator = value ? "[PASS]" : "[FAIL]"
          expect(pdf_content).to include(expected_indicator),
            "Missing pass/fail indicator for " \
              "#{assessment_type}.#{field_key}"
        elsif [true, false].include?(value) &&
            !field_key.to_s.end_with?("_comment")
          expected_value = if field_key.to_s.end_with?("_pass")
            value ? "[PASS]" : "[FAIL]"
          else
            (value ? "Yes" : "No")
          end
          expect(pdf_content).to include(expected_value),
            "Missing boolean value for #{assessment_type}.#{field_key}"
        elsif !field_key.to_s.end_with?("_comment")
          expect(pdf_content).to include(value.to_s),
            "Missing value '#{value}' for #{assessment_type}.#{field_key}"
        end
      end
    end

    # Validate core inspection details
    expect(pdf_content).to include(unit.name)
    expect(pdf_content).to include(unit.serial)
    date_format = inspection.inspection_date.strftime("%-d %B, %Y")
    expect(pdf_content).to include(date_format)
    report_id_key = "pdf.inspection.fields.report_id"
    report_id_text = "#{I18n.t(report_id_key)}: #{inspection.id}"
    expect(pdf_content).to include(report_id_text)

    # Validate inspection status with i18n
    expected_status = if inspection.passed?
      I18n.t("pdf.inspection.passed")
    else
      I18n.t("pdf.inspection.failed")
    end
    expect(pdf_content).to include(expected_status)

    # Validate key i18n strings are used
    expect_pdf_to_include_i18n_keys(pdf_content,
      "pdf.inspection.equipment_details",
      "pdf.inspection.assessments_section")

    # Validate unit details
    expect(pdf_content).to include(unit.manufacturer)
    expect(pdf_content).to include(inspection.operator)
  end

  scenario "validates i18n coverage across different PDF scenarios" do
    # Test failed inspection
    failed_inspection = create(
      :inspection, :completed, user: user, unit: unit, passed: false
    )
    visit inspection_path(failed_inspection, format: :pdf)
    failed_pdf_content = extract_pdf_text(page.source)
    expect(failed_pdf_content).to include(I18n.t("pdf.inspection.failed"))

    # Test incomplete inspection
    incomplete_inspection = create(
      :inspection, user: user, unit: unit, complete_date: nil
    )
    visit inspection_path(incomplete_inspection, format: :pdf)
    incomplete_pdf_content = extract_pdf_text(page.source)

    # Should still show all section headers even when incomplete
    %w[user_height structure anchorage materials].each do |assessment_type|
      header = I18n.t("forms.#{assessment_type}.header")
      expect(incomplete_pdf_content).to include(header)
    end

    # Test unit PDF with no inspections
    empty_unit = create(:unit, user: user, name: "Empty Unit")
    visit unit_path(empty_unit, format: :pdf)
    unit_pdf_content = extract_pdf_text(page.source)

    expect_pdf_to_include_i18n_keys(unit_pdf_content,
      "pdf.unit.fields.unit_id",
      "pdf.unit.details",
      "pdf.unit.no_completed_inspections")
  end

  scenario "handles edge cases and validates performance" do
    # Test with long comments (performance test)
    long_comment = "Detailed assessment comment " * 50
    inspection.user_height_assessment.update(
      containing_wall_height_comment: long_comment
    )

    start_time = Time.current
    visit inspection_path(inspection, format: :pdf)
    pdf_content = extract_pdf_text(page.source)
    generation_time = Time.current - start_time

    expect(generation_time).to be < 5.seconds
    expect(pdf_content).to be_present
    expect(pdf_content.length).to be > 1000 # Should have substantial content

    # Test Unicode handling
    unit.update(
      name: "Ünicøde Unit 😎",
      manufacturer: "Émoji Company 🏭"
    )

    visit inspection_path(inspection, format: :pdf)
    unicode_pdf_content = extract_pdf_text(page.source)
    expect(unicode_pdf_content).to be_present
    expect(unicode_pdf_content.encoding.name).to eq("UTF-8")
  end

  private

  define_method(:get_expected_pdf_label) do |field_key, field_label, fields, _assessment_type|
    base_field = field_key.to_s.sub(/_(pass|comment)$/, "")

    if field_key.to_s.end_with?("_pass")
      base_field_key = base_field.to_sym
      return fields[base_field_key] if fields.key?(base_field_key)
    end

    field_label
  end

  define_method(:extract_pdf_text) do |pdf_data|
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    reader.pages.map(&:text).join(" ")
  end
end
