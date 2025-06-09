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
  def expect_no_assessment_messages(pdf_text, unit = nil)
    assessment_types = %w[user_height structure anchorage materials fan]
    
    # Only check for slide if unit has a slide
    assessment_types << 'slide' if unit&.has_slide?
    
    # Only check for enclosed if unit is totally enclosed
    assessment_types << 'enclosed' if unit&.is_totally_enclosed?
    
    assessment_types.each do |type|
      title = I18n.t("inspections.assessments.#{type}.title")
      expect(pdf_text).to include(I18n.t("pdf.inspection.no_assessment_data", assessment_type: title))
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