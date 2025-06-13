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
  def expect_no_assessment_messages(pdf_text, inspection = nil)
    assessment_types = %w[user_height structure anchorage materials fan]

    # Only check for slide if inspection has a slide
    assessment_types << "slide" if inspection&.has_slide?

    # Only check for enclosed if inspection is totally enclosed
    assessment_types << "enclosed" if inspection&.is_totally_enclosed?

    assessment_types.each do |type|
      # Map assessment types to correct form names
      form_type = case type
      when "user_height" then "tallest_user_height"
      else type
      end
      
      title = I18n.t("forms.#{form_type}.header")
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
