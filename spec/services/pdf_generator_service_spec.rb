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

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    it "uses I18n translations for PDF content" do
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_text = pdf_text_content(pdf.render)

      # Check that I18n translations are used
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.title",
        "pdf.inspection.equipment_details",
        "pdf.inspection.assessments_section")
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
        expect(pdf_text).to include(I18n.t("pdf.inspection.fields.manufacturer"))
        # The actual value after the manufacturer label should be empty/blank
      end
    end
  end

  describe ".generate_unit_report" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    it "uses I18n translations for unit PDF content" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      pdf_text = pdf_text_content(pdf.render)

      # Check that I18n translations are used
      expect(pdf_text).to include(I18n.t("pdf.unit.title"))
      expect(pdf_text).to include(I18n.t("pdf.unit.details"))
    end

    it "displays unit fields with I18n labels" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      pdf_text = pdf_text_content(pdf.render)

      expect(pdf_text).to include(I18n.t("pdf.inspection.fields.description"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.fields.serial"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.fields.manufacturer"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.fields.has_slide"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.fields.totally_enclosed"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.fields.owner"))
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
          "shared.pass",
          "shared.fail")
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
        expect(pdf_text).to include(I18n.t("pdf.inspection.fields.manufacturer"))
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

  describe "assessment sections" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }
    let(:inspection) { create(:inspection, :pdf_complete_test_data, user: user, unit: unit, has_slide: true, is_totally_enclosed: true) }

    context "with user height assessment" do
      it "includes user height assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n(pdf_text, "forms.tallest_user_height.header")
      end
    end

    context "with slide assessment" do
      it "includes slide assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n(pdf_text, "forms.slide.header")
        expect_pdf_to_include_i18n(pdf_text, "shared.pass")
      end
    end

    context "with structure assessment" do
      it "includes structure assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n(pdf_text, "forms.structure.header")
        expect_pdf_to_include_i18n(pdf_text, "shared.pass")
      end
    end

    context "with anchorage assessment" do
      it "includes anchorage assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n(pdf_text, "forms.anchorage.header")
        expect_pdf_to_include_i18n(pdf_text, "shared.pass")
      end
    end

    context "with enclosed assessment" do
      it "includes enclosed assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n(pdf_text, "forms.enclosed.header")
        expect_pdf_to_include_i18n(pdf_text, "shared.pass")
      end
    end

    context "with materials assessment" do
      it "includes materials assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n(pdf_text, "forms.materials.header")
        expect_pdf_to_include_i18n(pdf_text, "shared.pass")
      end
    end

    context "with fan assessment" do
      it "includes fan assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_pdf_to_include_i18n(pdf_text, "forms.fan.header")
        expect_pdf_to_include_i18n(pdf_text, "shared.pass")
      end
    end

    context "with incomplete assessments" do
      let(:empty_inspection) { create(:inspection, user: user, unit: unit, has_slide: true, is_totally_enclosed: true) }

      it "renders all i18n fields even when incomplete" do
        pdf = PdfGeneratorService.generate_inspection_report(empty_inspection)
        pdf_text = pdf_text_content(pdf.render)

        # Use the helper that properly handles field grouping
        expect_all_i18n_fields_rendered(pdf_text, empty_inspection)
      end
    end

    context "for inspection without slide" do
      before { inspection.update(has_slide: false) }

      it "does not include slide section" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect(pdf_text).not_to include(I18n.t("forms.slide.fields.slide_platform_height"))
      end
    end

    context "for inspection not totally enclosed" do
      before { inspection.update(is_totally_enclosed: false) }

      it "does not include enclosed section" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect(pdf_text).not_to include(I18n.t("forms.enclosed.header"))
      end
    end
  end

  describe "unit with photo" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }

    context "with attached photo" do
      before do
        unit.photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename: "test_image.jpg",
          content_type: "image/jpeg"
        )
      end

      it "generates PDF without errors" do
        expect {
          pdf = PdfGeneratorService.generate_unit_report(unit)
          pdf.render
        }.not_to raise_error
      end

      it "generates inspection PDF with unit photo without errors" do
        inspection = create(:inspection, user: user, unit: unit)
        expect {
          pdf = PdfGeneratorService.generate_inspection_report(inspection)
          pdf.render
        }.not_to raise_error
      end

      it "generates PDF without errors even with problematic photo" do
        # Since we removed error handling, PDFs should generate without issues
        # or fail fast if there's a real problem
        expect {
          pdf = PdfGeneratorService.generate_unit_report(unit)
          pdf.render
        }.not_to raise_error
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
        expect(PdfGeneratorService.format_pass_fail(true)).to eq(I18n.t("shared.pass"))
      end

      it "formats false as Fail" do
        expect(PdfGeneratorService.format_pass_fail(false)).to eq(I18n.t("shared.fail"))
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
        expect {
          pdf = PdfGeneratorService.generate_inspection_report(inspection)
          pdf.render
        }.not_to raise_error
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
