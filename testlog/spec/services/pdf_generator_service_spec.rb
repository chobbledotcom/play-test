require "rails_helper"
require "pdf/inspector"

RSpec.describe PdfGeneratorService do
  # Test I18n integration
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end
  describe ".generate_inspection_certificate" do
    let(:user) { create(:user) }
    let(:inspection) { create(:inspection, user: user) }

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    it "uses I18n translations for PDF content" do
      pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      # Check that I18n translations are used
      expect(pdf_text).to include(I18n.t("pdf.inspection.title"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.equipment_details"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.inspection_results"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.verification"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.footer_text"))
    end

    it "handles different inspection statuses with I18n" do
      inspection.update(passed: true)
      pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")
      expect(pdf_text).to include(I18n.t("pdf.inspection.passed"))

      inspection.update(passed: false)
      pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")
      expect(pdf_text).to include(I18n.t("pdf.inspection.failed"))
    end

    context "with comments" do
      before do
        inspection.update(comments: "Test comments")
      end

      it "generates PDF with comments section using I18n" do
        pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.inspection.comments"))
        expect(pdf_text).to include("Test comments")
      end
    end

    context "with missing manufacturer" do
      before do
        inspection.unit.update(manufacturer: nil)
      end

      it "shows 'not specified' text using I18n" do
        pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.inspection.fields.not_specified"))
      end
    end
  end

  describe ".generate_unit_certificate" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_unit_certificate(unit)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    it "uses I18n translations for unit PDF content" do
      pdf = PdfGeneratorService.generate_unit_certificate(unit)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      # Check that I18n translations are used
      expect(pdf_text).to include(I18n.t("pdf.unit.title"))
      expect(pdf_text).to include(I18n.t("pdf.unit.details"))
      expect(pdf_text).to include(I18n.t("pdf.unit.verification"))
      expect(pdf_text).to include(I18n.t("pdf.unit.footer_text"))
    end

    it "displays unit fields with I18n labels" do
      pdf = PdfGeneratorService.generate_unit_certificate(unit)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      expect(pdf_text).to include(I18n.t("pdf.unit.fields.name"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.serial_number"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.manufacturer"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.type"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.owner"))
    end

    context "with inspections" do
      let!(:passed_inspection) { create(:inspection, user: user, unit: unit, passed: true) }
      let!(:failed_inspection) { create(:inspection, user: user, unit: unit, passed: false) }

      it "generates PDF with inspection history using I18n" do
        pdf = PdfGeneratorService.generate_unit_certificate(unit)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.unit.inspection_history"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.date"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.inspector"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.result"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.pass"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.fail"))
      end
    end

    context "with missing manufacturer" do
      before do
        unit.update(manufacturer: nil)
      end

      it "shows 'not specified' text using I18n" do
        pdf = PdfGeneratorService.generate_unit_certificate(unit)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.unit.fields.not_specified"))
      end
    end
  end
end
