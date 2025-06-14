module PdfTestHelpers
  # Extract all text content from a PDF
  def pdf_text_content(pdf_data)
    PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
  end

  # Check if PDF contains an i18n string
  def expect_pdf_to_include_i18n(pdf_text, key, **options)
    expect(pdf_text).to include(I18n.t(key, **options))
  end

  # Check multiple i18n keys exist in PDF
  def expect_pdf_to_include_i18n_keys(pdf_text, *keys)
    keys.each do |key|
      expect(pdf_text).to include(I18n.t(key))
    end
  end

  # Generate PDF and verify basic validity
  def get_pdf(path)
    page.driver.browser.get(path)
    verify_pdf_response
    page.driver.response.body
  end

  # Verify PDF response headers and format
  def verify_pdf_response
    expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
    expect(page.driver.response.body[0..3]).to eq("%PDF")
  end

  # Generate PDF and extract text content
  def get_pdf_text(path)
    pdf_data = get_pdf(path)
    pdf_text_content(pdf_data)
  end

  # Verify PDF generates without errors
  def expect_valid_pdf(pdf_data)
    expect { PDF::Inspector::Text.analyze(pdf_data) }.not_to raise_error
  end

  # Common pattern for testing PDF content
  def test_pdf_content(path)
    pdf_data = get_pdf(path)
    expect_valid_pdf(pdf_data)
    pdf_text_content(pdf_data)
  end

  # Get all PDF i18n keys from locale files
  def all_pdf_i18n_keys
    keys = []

    # Get all keys under pdf namespace
    I18n.backend.translations[:en][:pdf].each do |section, content|
      collect_keys(content, "pdf.#{section}", keys)
    end

    keys
  end

  # Check that all assessment sections show proper "no data" messages
  def expect_all_i18n_fields_rendered(pdf_text, inspection)
    Inspection::ASSESSMENT_TYPES.each do |assessment_name, _|
      # Skip conditional assessments if not applicable
      next if assessment_name == :slide_assessment && !inspection.has_slide?
      next if assessment_name == :enclosed_assessment && !inspection.is_totally_enclosed?
      
      # Get the i18n key for this assessment
      assessment_type = assessment_name.to_s.sub(/_assessment$/, "")
      assessment_type = "tallest_user_height" if assessment_type == "user_height"
      
      # Check header is present
      header = I18n.t("forms.#{assessment_type}.header")
      expect(pdf_text).to include(header)
      
      # Get ALL field labels from i18n and verify each one appears
      fields = I18n.t("forms.#{assessment_type}.fields")
      
      # Group fields to understand which are rendered together
      field_groups = {}
      fields.each_key do |field_key|
        field_str = field_key.to_s
        base_field = if field_str.end_with?("_pass")
          field_str.sub(/_pass$/, "")
        elsif field_str.end_with?("_comment")
          field_str.sub(/_comment$/, "")
        else
          field_str
        end
        
        field_groups[base_field] ||= []
        field_groups[base_field] << field_key
      end
      
      # Check each field group
      field_groups.each do |base_name, group_fields|
        # For grouped fields (base + _pass), we expect the base label
        # For standalone _pass fields, we expect that label
        # Comments don't render labels on their own
        
        main_field = group_fields.find { |f| !f.to_s.end_with?("_comment") }
        if main_field
          label = fields[main_field]
          expect(pdf_text).to include(label), 
            "Missing i18n field label '#{label}' for #{assessment_type}.#{main_field}"
        end
      end
    end
  end

  private

  def collect_keys(hash, prefix, keys)
    hash.each do |key, value|
      full_key = "#{prefix}.#{key}"
      if value.is_a?(Hash)
        collect_keys(value, full_key, keys)
      else
        keys << full_key
      end
    end
  end
end

RSpec.configure do |config|
  config.include PdfTestHelpers, type: :feature
  config.include PdfTestHelpers, type: :request
  config.include PdfTestHelpers, pdf: true
end
