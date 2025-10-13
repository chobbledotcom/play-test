# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::DisclaimerFooterRenderer do
  let(:pdf) { Prawn::Document.new }
  let(:user) { create(:user) }

  describe ".render_disclaimer_footer" do
    before do
      allow(described_class).to receive(:render_footer_content)
      allow(pdf).to receive(:cursor).and_return(500)
      allow(pdf).to receive(:move_cursor_to)
      allow(pdf).to receive(:bounding_box).and_yield
      allow(pdf).to receive(:move_down)
      allow(pdf.bounds).to receive(:width).and_return(540)
    end

    context "when branded" do
      it "saves and restores cursor position" do
        original_y = 500
        expect(pdf).to receive(:cursor).and_return(original_y)
        expect(pdf).to receive(:move_cursor_to).with(
          PdfGeneratorService::Configuration::FOOTER_HEIGHT
        )
        expect(pdf).to receive(:move_cursor_to).with(original_y)
        described_class.render_disclaimer_footer(pdf, user)
      end

      it "creates bounding box for footer" do
        expect(pdf).to receive(:bounding_box).with(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          height: PdfGeneratorService::Configuration::FOOTER_HEIGHT
        )
        described_class.render_disclaimer_footer(pdf, user)
      end

      it "renders footer content" do
        expect(described_class).to receive(:render_footer_content)
          .with(pdf, user)
        described_class.render_disclaimer_footer(pdf, user)
      end
    end

    context "when unbranded" do
      it "does not render footer" do
        expect(pdf).not_to receive(:bounding_box)
        described_class.render_disclaimer_footer(pdf, user, unbranded: true)
      end
    end
  end

  describe ".render_footer_content" do
    let(:signature) do
      double("signature", attached?: true, download: "sig_data")
    end
    let(:logo) { double("logo", attached?: true, download: "logo_data") }

    before do
      allow(described_class).to receive(:render_disclaimer_header)
      allow(pdf).to receive(:move_down)
      allow(pdf).to receive(:table)
      allow(pdf).to receive(:make_cell).and_return(double("cell"))
      allow(pdf.bounds).to receive(:width).and_return(540)
    end

    context "without signature or logo" do
      before do
        allow(user).to receive(:signature).and_return(
          double("signature", attached?: false)
        )
        allow(user).to receive(:logo).and_return(
          double("logo", attached?: false)
        )
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PDF_LOGO").and_return(nil)
      end

      it "renders disclaimer header" do
        expect(described_class).to receive(:render_disclaimer_header).with(pdf)
        described_class.render_footer_content(pdf, user)
      end

      it "moves down for internal padding" do
        expect(pdf).to receive(:move_down).with(
          PdfGeneratorService::Configuration::FOOTER_INTERNAL_PADDING
        )
        described_class.render_footer_content(pdf, user)
      end

      it "creates table with disclaimer text only" do
        expect(pdf).to receive(:make_cell).with(
          hash_including(
            content: I18n.t("pdf.disclaimer.text"),
            size: PdfGeneratorService::Configuration::DISCLAIMER_TEXT_SIZE
          )
        )
        expect(pdf).to receive(:table)
        described_class.render_footer_content(pdf, user)
      end
    end

    context "with signature" do
      before do
        allow(user).to receive(:signature).and_return(signature)
        allow(user).to receive(:logo).and_return(
          double("logo", attached?: false)
        )
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PDF_LOGO").and_return(nil)
      end

      it "creates table with disclaimer and signature cells" do
        expect(pdf).to receive(:make_cell).at_least(:once)
        expect(pdf).to receive(:table)
        described_class.render_footer_content(pdf, user)
      end
    end

    context "with logo" do
      before do
        allow(user).to receive(:signature).and_return(
          double("signature", attached?: false)
        )
        allow(user).to receive(:logo).and_return(logo)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PDF_LOGO").and_return("true")
      end

      it "creates table with disclaimer and logo cells" do
        expect(pdf).to receive(:make_cell).at_least(:once)
        expect(pdf).to receive(:table)
        described_class.render_footer_content(pdf, user)
      end
    end

    context "with both signature and logo" do
      before do
        allow(user).to receive(:signature).and_return(signature)
        allow(user).to receive(:logo).and_return(logo)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PDF_LOGO").and_return("true")
      end

      it "creates table with all three cells" do
        expect(pdf).to receive(:make_cell).at_least(3).times
        expect(pdf).to receive(:table)
        described_class.render_footer_content(pdf, user)
      end
    end
  end

  describe ".render_disclaimer_header" do
    before do
      allow(pdf).to receive(:text)
      allow(pdf).to receive(:stroke_horizontal_rule)
    end

    it "renders header text" do
      expect(pdf).to receive(:text).with(
        I18n.t("pdf.disclaimer.header"),
        size: PdfGeneratorService::Configuration::DISCLAIMER_HEADER_SIZE,
        style: :bold
      )
      described_class.render_disclaimer_header(pdf)
    end

    it "draws horizontal rule" do
      expect(pdf).to receive(:stroke_horizontal_rule)
      described_class.render_disclaimer_header(pdf)
    end
  end

  describe ".measure_footer_height" do
    context "when branded" do
      it "returns footer height" do
        result = described_class.measure_footer_height(unbranded: false)
        expect(result).to eq(
          PdfGeneratorService::Configuration::FOOTER_HEIGHT
        )
      end
    end

    context "when unbranded" do
      it "returns 0" do
        result = described_class.measure_footer_height(unbranded: true)
        expect(result).to eq(0)
      end
    end
  end
end
