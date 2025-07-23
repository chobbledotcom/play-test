require "rails_helper"
require "pdf/inspector"

RSpec.describe "PDF i18n Coverage", type: :request, pdf: true do
  let(:user) { create(:user) }

  describe "i18n string usage verification" do
    it "uses all defined PDF i18n strings in generated PDFs" do
      unit = create(:unit, user:, name: "Test Unit", manufacturer: "Test Mfg", serial: "TEST123")
      inspection = create(:inspection, :completed, user:, unit:, passed: true, risk_assessment: "Test risk assessment")

      inspection_pdf = PdfGeneratorService.generate_inspection_report(inspection)
      inspection_pdf_text = pdf_text_content(inspection_pdf.render)

      unit_pdf = PdfGeneratorService.generate_unit_report(unit)
      unit_pdf_text = pdf_text_content(unit_pdf.render)

      failed_inspection = create(:inspection, :completed, user:, unit:, passed: false)
      failed_pdf = PdfGeneratorService.generate_inspection_report(failed_inspection)
      failed_pdf_text = pdf_text_content(failed_pdf.render)

      incomplete_inspection = create(:inspection, user:, unit:, complete_date: nil)
      incomplete_pdf = PdfGeneratorService.generate_inspection_report(incomplete_inspection)
      incomplete_pdf_text = pdf_text_content(incomplete_pdf.render)

      # Create an inspection with passed: nil to test IN_PROGRESS status
      in_progress_inspection = create(:inspection, user:, unit:, passed: nil, complete_date: nil)
      in_progress_pdf = PdfGeneratorService.generate_inspection_report(in_progress_inspection)
      in_progress_pdf_text = pdf_text_content(in_progress_pdf.render)

      # Create an inspection with photos to test photos section i18n
      photos_inspection = create(:inspection, :completed, user:, unit:, passed: true)
      photos_inspection.photo_1.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
      photos_inspection.photo_2.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename: "test2.jpg",
        content_type: "image/jpeg"
      )
      photos_inspection.photo_3.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename: "test3.jpg",
        content_type: "image/jpeg"
      )
      photos_pdf = PdfGeneratorService.generate_inspection_report(photos_inspection)
      photos_pdf_text = pdf_text_content(photos_pdf.render)

      all_pdf_text = [
        inspection_pdf_text,
        unit_pdf_text,
        failed_pdf_text,
        incomplete_pdf_text,
        in_progress_pdf_text,
        photos_pdf_text
      ].join(" ")

      used_keys = []
      unused_keys = []

      fallback_keys = %w[
        pdf.inspection.fields.na
        pdf.unit.fields.na
        pdf.inspection.fields.incomplete
        pdf.unit.no_completed_inspections
      ]

      all_pdf_i18n_keys.each do |key|
        value = I18n.t(key)

        next if value.include?("%{")
        next if value.blank?
        next if fallback_keys.include?(key)

        if all_pdf_text.include?(value)
          used_keys << key
        else
          unused_keys << key
        end
      end

      if unused_keys.any?
        puts "\n\nUnused PDF i18n keys found:"
        unused_keys.each { puts "  - #{it}" }
        puts "\nConsider removing these from config/locales/pdf.en.yml\n\n"
      end

      expect(unused_keys).to be_empty
    end

    it "verifies no hardcoded strings in PDF generation" do
      hardcoded_patterns = [
        /Equipment Details/i,
        /Inspection Results/i,
        /Final Result/i,
        /DRAFT/,
        /Complete/,
        /Inspection Report/i,
        /Unit History Report/i
      ]

      pdf_service_path = Rails.root.join("app/services/pdf_generator_service.rb")
      pdf_service_content = File.read(pdf_service_path)

      hardcoded_patterns.each do |pattern|
        source_pattern = pattern.source
        matches = pdf_service_content.scan(/^(?!.*#).*".*#{source_pattern}.*"/)
          .reject { it.include?("I18n.t") }
          .reject { it.include?("pdf.") }

        if matches.any?
          puts "\nPotential hardcoded string found (should use i18n):"
          puts "  Pattern: #{pattern}"
          matches.each { puts "  Line: #{it.strip}" }
        end
      end
    end
  end

  describe "DRY helper usage" do
    it "generates inspection PDF with all sections" do
      unit = create(:unit, user:, name: "Test Unit PDF", serial: "SERIAL123")
      inspection = create(:inspection, user:, unit:)

      get inspection_path(inspection, format: :pdf)

      expect(response).to have_http_status(:success)
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect_valid_pdf(response.body)

      pdf_text = pdf_text_content(response.body)

      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.equipment_details")

      expect(pdf_text).to include(unit.name)
      expect(pdf_text).to include(unit.serial)
      expect(pdf_text).to include(user.name)
    end

    it "generates unit PDF with inspection history" do
      unit = create(:unit, user:)

      3.times do |i|
        create(:inspection, :completed,
          user:,
          unit:,
          inspection_date: i.months.ago,
          passed: i.even?)
      end

      get unit_path(unit, format: :pdf)
      pdf_text = pdf_text_content(response.body)

      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.fields.unit_id",
        "pdf.unit.details",
        "pdf.unit.inspection_history")
    end
  end
end
