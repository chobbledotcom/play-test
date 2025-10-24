# typed: false

require "rails_helper"

RSpec.describe PdfGeneratorService::Utilities do
  describe ".format_pass_fail" do
    it "formats true as pass text" do
      expect(described_class.format_pass_fail(true)).to eq(
        I18n.t("shared.pass_pdf")
      )
    end

    it "formats false as fail text" do
      expect(described_class.format_pass_fail(false)).to eq(
        I18n.t("shared.fail_pdf")
      )
    end

    it "formats nil as N/A text" do
      expect(described_class.format_pass_fail(nil)).to eq(
        I18n.t("pdf.inspection.fields.na")
      )
    end

    it "formats other values as N/A text" do
      expect(described_class.format_pass_fail("other")).to eq(
        I18n.t("pdf.inspection.fields.na")
      )
    end
  end

  describe ".format_measurement" do
    it "formats value with unit" do
      expect(described_class.format_measurement(5.5, "m")).to eq("5.5m")
    end

    it "formats value without unit" do
      expect(described_class.format_measurement(10)).to eq("10")
    end

    it "formats nil as N/A text" do
      expect(described_class.format_measurement(nil)).to eq(
        I18n.t("pdf.inspection.fields.na")
      )
    end

    it "formats nil with unit as N/A text" do
      expect(described_class.format_measurement(nil, "kg")).to eq(
        I18n.t("pdf.inspection.fields.na")
      )
    end
  end

  describe ".format_dimension" do
    it "formats numeric dimension" do
      expect(described_class.format_dimension(5.5)).to eq("5.5")
    end

    it "removes .0 from whole numbers" do
      expect(described_class.format_dimension(5.0)).to eq("5")
    end

    it "formats nil as empty string" do
      expect(described_class.format_dimension(nil)).to eq("")
    end

    it "formats zero as 0" do
      expect(described_class.format_dimension(0)).to eq("0")
    end
  end

  describe ".format_date" do
    it "formats date in correct format" do
      date = Date.new(2024, 7, 31)
      expect(described_class.format_date(date)).to eq("31 July, 2024")
    end

    it "formats nil as N/A text" do
      expect(described_class.format_date(nil)).to eq(
        I18n.t("pdf.inspection.fields.na")
      )
    end
  end

  describe ".truncate_text" do
    it "returns text unchanged if within max length" do
      text = "Short text"
      expect(described_class.truncate_text(text, 20)).to eq("Short text")
    end

    it "truncates text with ellipsis if over max length" do
      text = "This is a very long text that should be truncated"
      result = described_class.truncate_text(text, 20)
      expect(result).to eq("This is a very long ...")
      expect(result.length).to eq(23) # 20 chars + "..."
    end

    it "returns empty string for nil text" do
      expect(described_class.truncate_text(nil, 20)).to eq("")
    end

    it "handles zero max length" do
      expect(described_class.truncate_text("text", 0)).to eq("...")
    end
  end

  describe ".add_draft_watermark" do
    let(:pdf) { Prawn::Document.new }

    it "adds watermarks to a single page PDF" do
      # Mock the PDF methods
      expect(pdf).to receive(:page_count).and_return(1)
      expect(pdf).to receive(:go_to_page).with(1)
      expect(pdf).to receive(:transparent).with(
        PdfGeneratorService::Configuration::WATERMARK_TRANSPARENCY
      ).and_yield
      expect(pdf).to receive(:fill_color).with("FF0000").ordered
      expect(pdf).to receive(:fill_color).with("000000").ordered

      # Expect 15 watermarks (5 y positions * 3 x positions)
      expect(pdf).to receive(:text_box).exactly(15).times

      described_class.add_draft_watermark(pdf)
    end

    it "adds watermarks to all pages of a multi-page PDF" do
      # Mock the PDF methods for 3 pages
      expect(pdf).to receive(:page_count).and_return(3)
      expect(pdf).to receive(:go_to_page).with(1).ordered
      expect(pdf).to receive(:go_to_page).with(2).ordered
      expect(pdf).to receive(:go_to_page).with(3).ordered
      expect(pdf).to receive(:transparent).exactly(3).times.and_yield
      expect(pdf).to receive(:fill_color).with("FF0000").exactly(3).times
      expect(pdf).to receive(:fill_color).with("000000").exactly(3).times

      # Expect 45 watermarks total (15 per page * 3 pages)
      expect(pdf).to receive(:text_box).exactly(45).times

      described_class.add_draft_watermark(pdf)
    end

    it "uses correct watermark text from i18n" do
      watermark_text = I18n.t("pdf.inspection.watermark.draft")

      expect(pdf).to receive(:page_count).and_return(1)
      expect(pdf).to receive(:go_to_page).with(1)
      expect(pdf).to receive(:transparent).and_yield
      expect(pdf).to receive(:fill_color).twice

      # Verify correct text is used
      expect(pdf).to receive(:text_box).with(
        watermark_text,
        hash_including(
          width: PdfGeneratorService::Configuration::WATERMARK_WIDTH,
          height: PdfGeneratorService::Configuration::WATERMARK_HEIGHT,
          size: PdfGeneratorService::Configuration::WATERMARK_TEXT_SIZE,
          style: :bold,
          align: :center,
          valign: :top
        )
      ).exactly(15).times

      described_class.add_draft_watermark(pdf)
    end

    it "positions watermarks in a 5x3 grid" do
      pdf_bounds_height = 800
      pdf_bounds_width = 600

      allow(pdf).to receive_message_chain(:bounds, :height).and_return(pdf_bounds_height)
      allow(pdf).to receive_message_chain(:bounds, :width).and_return(pdf_bounds_width)
      expect(pdf).to receive(:page_count).and_return(1)
      expect(pdf).to receive(:go_to_page).with(1)
      expect(pdf).to receive(:transparent).and_yield
      expect(pdf).to receive(:fill_color).twice

      # Expected y positions (5 rows)
      expected_y_positions = [0.10, 0.30, 0.50, 0.70, 0.9].map { |pct| pdf_bounds_height * pct }
      # Expected x positions (3 columns, centered)
      watermark_width = PdfGeneratorService::Configuration::WATERMARK_WIDTH
      expected_x_positions = [0.15, 0.50, 0.85].map { |pct| pdf_bounds_width * pct - (watermark_width / 2) }

      # Verify each position is used
      expected_y_positions.each do |y|
        expected_x_positions.each do |x|
          expect(pdf).to receive(:text_box).with(
            anything,
            hash_including(at: [x, y])
          ).once
        end
      end

      described_class.add_draft_watermark(pdf)
    end

    it "resets fill color to black after adding watermarks" do
      expect(pdf).to receive(:page_count).and_return(1)
      expect(pdf).to receive(:go_to_page)
      expect(pdf).to receive(:transparent).and_yield
      expect(pdf).to receive(:text_box).exactly(15).times

      # Verify color changes: red for watermarks, then back to black
      expect(pdf).to receive(:fill_color).with("FF0000").ordered
      expect(pdf).to receive(:fill_color).with("000000").ordered

      described_class.add_draft_watermark(pdf)
    end

    it "handles PDF with zero pages gracefully" do
      expect(pdf).to receive(:page_count).and_return(0)
      expect(pdf).not_to receive(:go_to_page)
      expect(pdf).not_to receive(:text_box)

      described_class.add_draft_watermark(pdf)
    end

    it "uses correct text styling for watermarks" do
      expect(pdf).to receive(:page_count).and_return(1)
      expect(pdf).to receive(:go_to_page).with(1)
      expect(pdf).to receive(:transparent).and_yield
      expect(pdf).to receive(:fill_color).twice

      # Verify text box is called with correct styling
      expect(pdf).to receive(:text_box).with(
        anything,
        hash_including(
          size: PdfGeneratorService::Configuration::WATERMARK_TEXT_SIZE,
          style: :bold,
          align: :center,
          valign: :top
        )
      ).exactly(15).times

      described_class.add_draft_watermark(pdf)
    end
  end
end
