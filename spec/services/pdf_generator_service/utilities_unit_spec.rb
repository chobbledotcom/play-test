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
end
