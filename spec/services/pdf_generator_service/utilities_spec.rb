require "rails_helper"

RSpec.describe PdfGeneratorService::Utilities do
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end

  describe ".truncate_text" do
    context "with nil text" do
      it "returns empty string" do
        expect(described_class.truncate_text(nil, 20)).to eq("")
      end
    end

    context "with text shorter than max length" do
      it "returns full text unchanged" do
        text = "Short text"
        expect(described_class.truncate_text(text, 20)).to eq("Short text")
      end
    end

    context "with text equal to max length" do
      it "returns full text unchanged" do
        text = "Exactly twenty chars"
        expect(described_class.truncate_text(text, 20)).to eq("Exactly twenty chars")
      end
    end

    context "with text longer than max length" do
      it "truncates text and adds ellipsis" do
        text = "This is a very long text that should be truncated"
        expect(described_class.truncate_text(text, 20)).to eq("This is a very long ...")
      end
    end

    context "with empty string" do
      it "returns empty string" do
        expect(described_class.truncate_text("", 20)).to eq("")
      end
    end

    context "with zero max length" do
      it "returns ellipsis only" do
        expect(described_class.truncate_text("some text", 0)).to eq("...")
      end
    end
  end

  describe ".format_dimension" do
    context "with nil value" do
      it "returns empty string" do
        expect(described_class.format_dimension(nil)).to eq("")
      end
    end

    context "with integer value" do
      it "returns value as string" do
        expect(described_class.format_dimension(5)).to eq("5")
      end
    end

    context "with decimal ending in .0" do
      it "removes trailing .0" do
        expect(described_class.format_dimension(5.0)).to eq("5")
      end
    end

    context "with decimal not ending in .0" do
      it "preserves decimal places" do
        expect(described_class.format_dimension(5.5)).to eq("5.5")
      end
    end

    context "with string value" do
      it "processes string format" do
        expect(described_class.format_dimension("10.0")).to eq("10")
        expect(described_class.format_dimension("10.5")).to eq("10.5")
      end
    end
  end

  describe ".format_pass_fail" do
    context "with true value" do
      it "returns pass translation" do
        expect(described_class.format_pass_fail(true)).to eq(I18n.t("pdf.inspection.fields.pass"))
      end
    end

    context "with false value" do
      it "returns fail translation" do
        expect(described_class.format_pass_fail(false)).to eq(I18n.t("pdf.inspection.fields.fail"))
      end
    end

    context "with nil value" do
      it "returns N/A translation" do
        expect(described_class.format_pass_fail(nil)).to eq(I18n.t("pdf.inspection.fields.na"))
      end
    end

    context "with other values" do
      it "returns N/A translation for string" do
        expect(described_class.format_pass_fail("unknown")).to eq(I18n.t("pdf.inspection.fields.na"))
      end

      it "returns N/A translation for number" do
        expect(described_class.format_pass_fail(1)).to eq(I18n.t("pdf.inspection.fields.na"))
      end
    end
  end

  describe ".format_measurement" do
    context "with nil value" do
      it "returns N/A translation" do
        expect(described_class.format_measurement(nil)).to eq(I18n.t("pdf.inspection.fields.na"))
        expect(described_class.format_measurement(nil, "m")).to eq(I18n.t("pdf.inspection.fields.na"))
      end
    end

    context "with value and no unit" do
      it "returns value as string" do
        expect(described_class.format_measurement(10)).to eq("10")
        expect(described_class.format_measurement(10.5)).to eq("10.5")
      end
    end

    context "with value and unit" do
      it "concatenates value and unit" do
        expect(described_class.format_measurement(10, "m")).to eq("10m")
        expect(described_class.format_measurement(25.5, "mm")).to eq("25.5mm")
      end
    end

    context "with empty unit" do
      it "returns just the value" do
        expect(described_class.format_measurement(15, "")).to eq("15")
      end
    end

    context "with zero value" do
      it "formats zero correctly" do
        expect(described_class.format_measurement(0)).to eq("0")
        expect(described_class.format_measurement(0, "kg")).to eq("0kg")
      end
    end
  end

  describe ".add_draft_watermark" do
    let(:pdf_double) { double("pdf") }
    let(:bounds_double) { double("bounds", height: 800, width: 600) }

    before do
      allow(pdf_double).to receive(:page_count).and_return(2)
      allow(pdf_double).to receive(:go_to_page)
      allow(pdf_double).to receive(:transparent).and_yield
      allow(pdf_double).to receive(:fill_color)
      allow(pdf_double).to receive(:text_box)
      allow(pdf_double).to receive(:bounds).and_return(bounds_double)
    end

    it "processes each page in the PDF" do
      described_class.add_draft_watermark(pdf_double)

      expect(pdf_double).to have_received(:go_to_page).with(1)
      expect(pdf_double).to have_received(:go_to_page).with(2)
    end

    it "sets red colour for watermark" do
      described_class.add_draft_watermark(pdf_double)

      expect(pdf_double).to have_received(:fill_color).with("FF0000").twice
    end

    it "resets colour to black after watermark" do
      described_class.add_draft_watermark(pdf_double)

      expect(pdf_double).to have_received(:fill_color).with("000000").twice
    end

    it "uses transparency for watermark" do
      transparency_value = PdfGeneratorService::Configuration::WATERMARK_TRANSPARENCY

      described_class.add_draft_watermark(pdf_double)

      expect(pdf_double).to have_received(:transparent).with(transparency_value).twice
    end

    it "adds multiple watermark text boxes" do
      described_class.add_draft_watermark(pdf_double)

      # Should add 15 watermarks per page (5 y-positions × 3 x-positions) × 2 pages = 30 total
      expect(pdf_double).to have_received(:text_box).exactly(30).times
    end

    it "uses draft watermark text from I18n" do
      described_class.add_draft_watermark(pdf_double)

      expect(pdf_double).to have_received(:text_box).with(
        I18n.t("pdf.inspection.watermark.draft"),
        hash_including(
          width: PdfGeneratorService::Configuration::WATERMARK_WIDTH,
          height: PdfGeneratorService::Configuration::WATERMARK_HEIGHT,
          size: PdfGeneratorService::Configuration::WATERMARK_TEXT_SIZE,
          style: :bold,
          align: :center,
          valign: :top
        )
      ).at_least(:once)
    end

    context "with single page PDF" do
      before do
        allow(pdf_double).to receive(:page_count).and_return(1)
      end

      it "processes only one page" do
        described_class.add_draft_watermark(pdf_double)

        expect(pdf_double).to have_received(:go_to_page).with(1)
        expect(pdf_double).not_to have_received(:go_to_page).with(2)
      end

      it "adds watermarks to single page only" do
        described_class.add_draft_watermark(pdf_double)

        # Should add 15 watermarks for single page (5 y-positions × 3 x-positions)
        expect(pdf_double).to have_received(:text_box).exactly(15).times
      end
    end

    context "with PDF with no pages" do
      before do
        allow(pdf_double).to receive(:page_count).and_return(0)
      end

      it "handles empty PDF gracefully" do
        expect { described_class.add_draft_watermark(pdf_double) }.not_to raise_error

        expect(pdf_double).not_to have_received(:go_to_page)
        expect(pdf_double).not_to have_received(:text_box)
      end
    end
  end
end
