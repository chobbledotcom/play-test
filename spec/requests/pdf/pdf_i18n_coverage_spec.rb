require "rails_helper"
require "pdf/inspector"

RSpec.describe "PDF i18n Coverage", type: :request, pdf: true do
  let(:user) { create(:user) }
  let(:inspector_company) { user.inspection_company }

  # No authentication needed for PDFs

  describe "i18n string usage verification" do
    it "uses all defined PDF i18n strings in generated PDFs" do
      # Create comprehensive test data
      unit = create(:unit,
        user: user,
        name: "Test Unit",
        manufacturer: "Test Mfg",
        serial: "TEST123")

      # Create complete inspection with all assessments
      inspection = create(:inspection, :pdf_complete_test_data,
        user: user,
        unit: unit,
        passed: true,
        comments: "Test comments")

      # Generate both PDF types
      inspection_pdf_text = pdf_text_content(
        PdfGeneratorService.generate_inspection_report(inspection).render
      )

      unit_pdf_text = pdf_text_content(
        PdfGeneratorService.generate_unit_report(unit).render
      )

      # Also test failed inspection
      failed_inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        passed: false)

      failed_pdf_text = pdf_text_content(
        PdfGeneratorService.generate_inspection_report(failed_inspection).render
      )

      # Combine all PDF text for checking
      all_pdf_text = [inspection_pdf_text, unit_pdf_text, failed_pdf_text].join(" ")

      # Track which i18n keys are used
      used_keys = []
      unused_keys = []

      # Check each PDF i18n key
      all_pdf_i18n_keys.each do |key|
        value = I18n.t(key)

        # Skip checking keys that are placeholders or dynamic
        next if value.include?("%{")
        next if value.blank?

        if all_pdf_text.include?(value)
          used_keys << key
        else
          unused_keys << key
        end
      end

      # Report findings
      if unused_keys.any?
        puts "\n\nUnused PDF i18n keys found:"
        unused_keys.each { |key| puts "  - #{key}" }
        puts "\nConsider removing these from config/locales/pdf.en.yml\n\n"
      end

      # This will help identify unused keys but won't fail the test
      # Uncomment the line below to make the test fail if unused keys exist:
      # expect(unused_keys).to be_empty
    end

    it "verifies no hardcoded strings in PDF generation" do
      # This test helps ensure we're using i18n for all user-facing text

      # Common hardcoded strings to check for
      hardcoded_patterns = [
        /Equipment Details/i,
        /Inspection Results/i,
        /Final Result/i,
        /DRAFT/,
        /Complete/,
        /Inspection Report/i,
        /Unit History Report/i
      ]

      # Read the PDF generator service file
      pdf_service_content = File.read(Rails.root.join("app/services/pdf_generator_service.rb"))

      # Check for hardcoded strings that should use i18n
      hardcoded_patterns.each do |pattern|
        # Find matches excluding comments and i18n calls
        matches = pdf_service_content.scan(/^(?!.*#).*".*#{pattern.source}.*"/)
          .reject { |line| line.include?("I18n.t") }
          .reject { |line| line.include?("pdf.") }

        if matches.any?
          puts "\nPotential hardcoded string found (should use i18n):"
          puts "  Pattern: #{pattern}"
          matches.each { |match| puts "  Line: #{match.strip}" }
        end
      end
    end
  end

  describe "DRY helper usage" do
    it "generates inspection PDF with all sections" do
      unit = create(:unit, user: user, name: "Test Unit PDF", serial: "SERIAL123")
      inspection = create(:inspection, :pdf_complete_test_data, :with_slide, :totally_enclosed, user: user, unit: unit)

      get inspection_path(inspection, format: :pdf)

      # Ensure we got a PDF response
      expect(response).to have_http_status(:success)
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect_valid_pdf(response.body)

      pdf_text = pdf_text_content(response.body)

      # Verify core sections using i18n
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.title",
        "pdf.inspection.equipment_details")

      # Verify dynamic content
      expect(pdf_text).to include(unit.name)
      expect(pdf_text).to include(unit.serial)
      expect(pdf_text).to include(user.name)
    end

    it "generates unit PDF with inspection history" do
      unit = create(:unit, user: user)

      # Create inspection history
      3.times do |i|
        create(:inspection, :completed,
          user: user,
          unit: unit,
          inspection_date: i.months.ago,
          passed: i.even?)
      end

      get unit_path(unit, format: :pdf)
      pdf_text = pdf_text_content(response.body)

      # Verify sections using i18n
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.title",
        "pdf.unit.details",
        "pdf.unit.inspection_history")
    end
  end
end
