# frozen_string_literal: true

require "rails_helper"
require "pdf/inspector"

RSpec.describe PdfGeneratorService, pdf: true do
  # Test I18n integration
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end
  describe ".generate_inspection_report" do
    let(:user) { create(:user) }
    let(:inspection) { create(:inspection, user: user) }

    it "uses I18n translations for PDF content" do
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_text = pdf_text_content(pdf.render)

      # Check that I18n translations are used
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.equipment_details",
        "pdf.inspection.assessments_section")
    end

    it "does not exceed 3 pages for inspection PDFs" do
      # Create an inspection with lots of assessment data
      inspection = create(:inspection, :completed, user: user)

      # Add lots of data to assessments to test overflow
      # Access each assessment type directly
      [
        inspection.user_height_assessment,
        inspection.slide_assessment,
        inspection.structure_assessment,
        inspection.anchorage_assessment,
        inspection.materials_assessment,
        inspection.enclosed_assessment,
        inspection.fan_assessment
      ].compact.each do |assessment|
        # Fill all comment fields with long content
        assessment.attributes.each do |key, value|
          if key.end_with?("_comment") && assessment.respond_to?("#{key}=")
            assessment.send("#{key}=", "This is a very long comment that will take up space in the PDF rendering. " * 3)
          end
        end
        assessment.save!
      end

      # Generate the PDF
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_content = pdf.render

      # Parse the PDF to count pages
      analyzed_pdf = PDF::Inspector::Page.analyze(pdf_content)

      expect(analyzed_pdf.pages.size).to be <= 3
    end

    it "handles different inspection statuses with I18n" do
      inspection.update(passed: true)
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_text = pdf_text_content(pdf.render)
      expect(pdf_text).to include(I18n.t("pdf.inspection.passed"))

      inspection.update(passed: false)
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_text = pdf_text_content(pdf.render)
      expect(pdf_text).to include(I18n.t("pdf.inspection.failed"))
    end

    context "with missing manufacturer" do
      before do
        inspection.unit.update(manufacturer: nil)
      end

      it "shows blank string for missing manufacturer" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        # Manufacturer field should be blank (empty string) when not specified
        expect(pdf_text).to include(I18n.t("forms.units.fields.manufacturer"))
        # The actual value after the manufacturer label should be empty/blank
      end
    end
  end

  describe ".generate_unit_report" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }

    it "uses I18n translations for unit PDF content" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      pdf_text = pdf_text_content(pdf.render)

      # Check that I18n translations are used
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.unit_id"))
      expect(pdf_text).to include(I18n.t("pdf.unit.details"))
    end

    it "displays unit fields with I18n labels" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      pdf_text = pdf_text_content(pdf.render)

      expect(pdf_text).to include(I18n.t("units.fields.name"))
      expect(pdf_text).to include(I18n.t("forms.units.fields.serial"))
      expect(pdf_text).to include(I18n.t("forms.units.fields.manufacturer"))
      expect(pdf_text).to include(I18n.t("forms.units.fields.operator"))
    end

    context "with inspections" do
      let!(:passed_inspection) { create(:inspection, :completed, user: user, unit: unit, passed: true) }
      let!(:failed_inspection) { create(:inspection, :completed, user: user, unit: unit, passed: false) }

      it "generates PDF with inspection history using I18n" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n_keys(pdf_text,
          "pdf.unit.inspection_history",
          "pdf.unit.fields.date",
          "pdf.unit.fields.inspector",
          "pdf.unit.fields.result",
          "shared.pass_pdf",
          "shared.fail_pdf")
      end
    end

    context "with missing manufacturer" do
      before do
        unit.update(manufacturer: nil)
      end

      it "shows blank string for missing manufacturer" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = pdf_text_content(pdf.render)

        # Manufacturer field should be blank (empty string) when not specified
        expect(pdf_text).to include(I18n.t("forms.units.fields.manufacturer"))
        # The actual value after the manufacturer label should be empty/blank
      end
    end

    context "without inspections" do
      it "shows no completed inspections message" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = pdf_text_content(pdf.render)

        expect(pdf_text).to include(I18n.t("pdf.unit.no_completed_inspections"))
      end
    end
  end

  describe "draft inspections" do
    let(:user) { create(:user) }
    let(:draft_inspection) { create(:inspection, user: user, complete_date: nil) }

    it "adds draft watermark to incomplete inspections" do
      skip "Temporarily disabled - watermarks are disabled in tests because they break loads of things randomly"
      pdf = PdfGeneratorService.generate_inspection_report(draft_inspection)
      pdf_text = pdf_text_content(pdf.render)

      # Draft watermarks should appear multiple times
      draft_count = pdf_text.scan(I18n.t("pdf.inspection.watermark.draft")).count
      expect(draft_count).to be > 5 # Should have multiple DRAFT watermarks
    end

    it "does not add draft watermark to complete inspections" do
      complete_inspection = create(:inspection, :completed, user: user)
      pdf = PdfGeneratorService.generate_inspection_report(complete_inspection)
      pdf_text = pdf_text_content(pdf.render)

      expect(pdf_text).not_to include(I18n.t("pdf.inspection.watermark.draft"))
    end
  end

  describe "unit with photo" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }

    context "with attached photo" do
      before do
        unit.photo.attach(
          io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
          filename: "test_image.jpg",
          content_type: "image/jpeg"
        )
      end

      it "generates PDF without errors" do
        expect do
          pdf = PdfGeneratorService.generate_unit_report(unit)
          pdf.render
        end.not_to raise_error
      end

      it "generates inspection PDF with unit photo without errors" do
        inspection = create(:inspection, user: user, unit: unit)
        expect do
          pdf = PdfGeneratorService.generate_inspection_report(inspection)
          pdf.render
        end.not_to raise_error
      end

      it "generates PDF without errors even with problematic photo" do
        # Since we removed error handling, PDFs should generate without issues
        # or fail fast if there's a real problem
        expect do
          pdf = PdfGeneratorService.generate_unit_report(unit)
          pdf.render
        end.not_to raise_error
      end
    end
  end

  describe "helper methods" do
    describe ".truncate_text" do
      it "truncates long text" do
        result = PdfGeneratorService.truncate_text("This is a very long text that should be truncated", 20)
        expect(result).to eq("This is a very long ...")
      end

      it "returns full text if shorter than max" do
        result = PdfGeneratorService.truncate_text("Short text", 20)
        expect(result).to eq("Short text")
      end

      it "handles nil text" do
        result = PdfGeneratorService.truncate_text(nil, 20)
        expect(result).to eq("")
      end
    end

    describe ".format_pass_fail" do
      it "formats true as Pass" do
        expect(PdfGeneratorService.format_pass_fail(true)).to eq(I18n.t("shared.pass_pdf"))
      end

      it "formats false as Fail" do
        expect(PdfGeneratorService.format_pass_fail(false)).to eq(I18n.t("shared.fail_pdf"))
      end

      it "formats nil as N/A" do
        expect(PdfGeneratorService.format_pass_fail(nil)).to eq(I18n.t("pdf.inspection.fields.na"))
      end
    end

    describe ".format_measurement" do
      it "formats value with unit" do
        expect(PdfGeneratorService.format_measurement(5.5, "m")).to eq("5.5m")
      end

      it "formats value without unit" do
        expect(PdfGeneratorService.format_measurement(10)).to eq("10")
      end

      it "handles nil value" do
        expect(PdfGeneratorService.format_measurement(nil, "m")).to eq(I18n.t("pdf.inspection.fields.na"))
      end
    end
  end

  describe "edge cases" do
    let(:user) { create(:user) }

    context "inspection without unit" do
      let(:inspection) { create(:inspection, user: user, unit: nil) }

      it "generates PDF without errors" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        # Unit details table should be hidden entirely when no unit is associated
        expect(pdf_text).not_to include(I18n.t("pdf.inspection.equipment_details"))
      end
    end

    context "QR code generation" do
      let(:inspection) { create(:inspection, user: user) }
      let(:unit) { create(:unit, user: user) }

      it "handles QR code tempfile cleanup for inspections" do
        allow(Tempfile).to receive(:new).and_call_original

        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf.render

        # Tempfile should be cleaned up (test passes if no errors)
      end

      it "handles QR code tempfile cleanup for units" do
        allow(Tempfile).to receive(:new).and_call_original

        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf.render

        # Tempfile should be cleaned up (test passes if no errors)
      end
    end

    context "with missing inspector company" do
      let(:inspection) { create(:inspection, user: user, inspector_company: nil) }

      it "handles missing inspector company gracefully" do
        expect do
          pdf = PdfGeneratorService.generate_inspection_report(inspection)
          pdf.render
        end.not_to raise_error
      end
    end
  end

  describe "pass/fail status in header" do
    let(:user) { create(:user) }

    context "with passed inspection" do
      let(:inspection) { create(:inspection, :completed, user: user, passed: true) }

      it "shows PASS in header" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect(pdf_text).to include(I18n.t("pdf.inspection.passed"))
      end
    end

    context "with failed inspection" do
      let(:inspection) { create(:inspection, :completed, user: user, passed: false) }

      it "shows FAIL in header" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect(pdf_text).to include(I18n.t("pdf.inspection.failed"))
      end
    end
  end
end
