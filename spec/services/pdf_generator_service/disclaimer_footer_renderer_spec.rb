# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::DisclaimerFooterRenderer do
  let(:pdf) { Prawn::Document.new }
  let(:user) { create(:user) }

  describe ".render_disclaimer_footer" do
    context "when should render footer" do
      before do
        allow(described_class).to receive(:should_render_footer?).and_return(true)
      end

      it "saves and restores cursor position" do
        original_y = pdf.cursor
        described_class.render_disclaimer_footer(pdf, user)
        expect(pdf.cursor).to eq(original_y)
      end

      it "moves to footer position" do
        expect(pdf).to receive(:move_cursor_to).with(
          PdfGeneratorService::Configuration::FOOTER_HEIGHT
        )
        expect(pdf).to receive(:move_cursor_to).with(anything) # restore position
        described_class.render_disclaimer_footer(pdf, user)
      end

      it "creates bounding box for footer" do
        expect(pdf).to receive(:bounding_box).with(
          [0, anything],
          width: pdf.bounds.width,
          height: PdfGeneratorService::Configuration::FOOTER_HEIGHT
        )
        described_class.render_disclaimer_footer(pdf, user)
      end

      it "adds top padding" do
        # It will receive move_down twice - once for FOOTER_TOP_PADDING and once for FOOTER_INTERNAL_PADDING
        expect(pdf).to receive(:move_down).at_least(:once)
        described_class.render_disclaimer_footer(pdf, user)
      end
    end

    context "when should not render footer" do
      before do
        allow(described_class).to receive(:should_render_footer?).and_return(false)
      end

      it "returns early without rendering" do
        expect(pdf).not_to receive(:move_cursor_to)
        expect(pdf).not_to receive(:bounding_box)
        described_class.render_disclaimer_footer(pdf, user)
      end
    end
  end

  describe ".should_render_footer?" do
    it "returns true for first page" do
      allow(pdf).to receive(:page_number).and_return(1)
      expect(described_class.send(:should_render_footer?, pdf)).to be true
    end

    it "returns false for subsequent pages" do
      allow(pdf).to receive(:page_number).and_return(2)
      expect(described_class.send(:should_render_footer?, pdf)).to be false
    end
  end

  describe ".render_footer_content" do
    before do
      # Stub the render methods to avoid complex PDF operations
      allow(described_class).to receive(:render_disclaimer_header)
      allow(described_class).to receive(:render_disclaimer_text_box)
      allow(described_class).to receive(:render_user_signature)
      allow(pdf).to receive(:move_down)
    end

    context "without signature" do
      before do
        allow(user).to receive_message_chain(:signature, :attached?).and_return(false)
      end

      it "renders disclaimer header" do
        expect(described_class).to receive(:render_disclaimer_header).with(pdf)
        described_class.send(:render_footer_content, pdf, user)
      end

      it "moves down for internal padding" do
        expect(pdf).to receive(:move_down).with(
          PdfGeneratorService::Configuration::FOOTER_INTERNAL_PADDING
        )
        described_class.send(:render_footer_content, pdf, user)
      end

      it "calculates full width for disclaimer when no signature" do
        expect(described_class).to receive(:render_disclaimer_text_box).with(
          pdf, anything, pdf.bounds.width
        )
        described_class.send(:render_footer_content, pdf, user)
      end

      it "does not render signature" do
        expect(described_class).not_to receive(:render_user_signature)
        described_class.send(:render_footer_content, pdf, user)
      end
    end

    context "with signature" do
      let(:signature) { double("signature", attached?: true) }

      before do
        allow(user).to receive(:signature).and_return(signature)
      end

      it "calculates partial width for disclaimer when signature exists" do
        expected_width = pdf.bounds.width *
          PdfGeneratorService::Configuration::DISCLAIMER_TEXT_WIDTH_PERCENT
        expect(described_class).to receive(:render_disclaimer_text_box).with(
          pdf, anything, expected_width
        )
        described_class.send(:render_footer_content, pdf, user)
      end

      it "renders signature" do
        expect(described_class).to receive(:render_user_signature)
        described_class.send(:render_footer_content, pdf, user)
      end
    end
  end

  describe ".render_disclaimer_header" do
    it "renders header text with correct size and style" do
      expect(pdf).to receive(:text).with(
        I18n.t("pdf.disclaimer.header"),
        size: PdfGeneratorService::Configuration::DISCLAIMER_HEADER_SIZE,
        style: :bold
      )
      described_class.send(:render_disclaimer_header, pdf)
    end

    it "draws horizontal rule" do
      expect(pdf).to receive(:stroke_horizontal_rule)
      described_class.send(:render_disclaimer_header, pdf)
    end
  end

  describe ".render_disclaimer_text_box" do
    let(:y_pos) { 100 }
    let(:width) { 200 }

    it "creates bounding box at correct position" do
      expect(pdf).to receive(:bounding_box).with(
        [0, y_pos],
        width: width,
        height: PdfGeneratorService::Configuration::DISCLAIMER_TEXT_HEIGHT
      )
      described_class.send(:render_disclaimer_text_box, pdf, y_pos, width)
    end

    it "renders text box with correct parameters" do
      expect(pdf).to receive(:text_box).with(
        I18n.t("pdf.disclaimer.text"),
        size: PdfGeneratorService::Configuration::DISCLAIMER_TEXT_SIZE,
        inline_format: true,
        valign: :top
      )
      described_class.send(:render_disclaimer_text_box, pdf, y_pos, width)
    end
  end

  describe ".calculate_disclaimer_width" do
    let(:bounds_width) { 500 }

    context "with signature" do
      it "returns partial width" do
        expected = bounds_width *
          PdfGeneratorService::Configuration::DISCLAIMER_TEXT_WIDTH_PERCENT
        result = described_class.send(
          :calculate_disclaimer_width, true, bounds_width
        )
        expect(result).to eq(expected)
      end
    end

    context "without signature" do
      it "returns full width" do
        result = described_class.send(
          :calculate_disclaimer_width, false, bounds_width
        )
        expect(result).to eq(bounds_width)
      end
    end
  end

  describe ".render_user_signature" do
    let(:x_offset) { 100 }
    let(:available_width) { 200 }
    let(:content_top_y) { 300 }
    let(:signature) { double("signature") }
    let(:blob) { double("blob", download: "image_data") }
    let(:image) { double("image", width: 150, height: 100, auto_orient: nil, to_blob: "processed_image_data") }

    before do
      allow(user).to receive(:signature).and_return(signature)
      allow(signature).to receive(:blob).and_return(blob)
      allow(PdfGeneratorService::ImageProcessor).to receive(:create_image)
        .and_return(image)
      allow(pdf).to receive(:stroke_color)
      allow(pdf).to receive(:line_width=)
      allow(pdf).to receive(:stroke_rectangle)
      allow(pdf).to receive(:text_box)
      allow(pdf).to receive(:image)
    end

    context "when signature renders successfully" do
      before do
        allow(PdfGeneratorService::PositionCalculator).to receive(:fit_dimensions)
          .and_return([120, 80])
        allow(PdfGeneratorService::ImageProcessor).to receive(:render_processed_image)
      end

      it "processes signature image" do
        expect(PdfGeneratorService::ImageProcessor).to receive(:create_image)
          .with(signature)
        described_class.send(:render_user_signature, pdf, user,
          x_offset, available_width, content_top_y)
      end

      it "calculates signature dimensions" do
        expect(described_class).to receive(:calculate_signature_dimensions)
          .with(image, available_width)
        described_class.send(:render_user_signature, pdf, user,
          x_offset, available_width, content_top_y)
      end

      it "draws border with correct color" do
        expect(pdf).to receive(:stroke_color).with("CCCCCC")
        expect(pdf).to receive(:line_width=).with(1)
        expect(pdf).to receive(:stroke_rectangle)
        described_class.send(:render_user_signature, pdf, user,
          x_offset, available_width, content_top_y)
      end

      it "renders signature image" do
        expect(PdfGeneratorService::ImageProcessor)
          .to receive(:render_processed_image)
        described_class.send(:render_user_signature, pdf, user,
          x_offset, available_width, content_top_y)
      end

      it "renders caption below signature" do
        expect(pdf).to receive(:text_box).with(
          I18n.t("pdf.signature.caption"),
          hash_including(
            align: :center,
            valign: :top,
            size: PdfGeneratorService::Configuration::DISCLAIMER_TEXT_SIZE
          )
        )
        described_class.send(:render_user_signature, pdf, user,
          x_offset, available_width, content_top_y)
      end

      it "resets stroke color to default" do
        expect(pdf).to receive(:stroke_color).with("CCCCCC").ordered
        expect(pdf).to receive(:stroke_color).with("000000").ordered
        described_class.send(:render_user_signature, pdf, user,
          x_offset, available_width, content_top_y)
      end
    end

    context "when signature rendering fails" do
      before do
        allow(PdfGeneratorService::ImageProcessor).to receive(:create_image)
          .and_raise(StandardError.new("Processing failed"))
      end

      it "logs error and continues" do
        expect(Rails.logger).to receive(:error)
          .with("Failed to render signature: Processing failed")
        expect do
          described_class.send(:render_user_signature, pdf, user,
            x_offset, available_width, content_top_y)
        end.not_to raise_error
      end
    end
  end

  describe ".calculate_signature_dimensions" do
    let(:image) { double("image", width: 300, height: 200) }
    let(:max_width) { 250 }

    it "calls PositionCalculator with adjusted width" do
      border_total_padding = 10
      internal_padding = PdfGeneratorService::Configuration::FOOTER_INTERNAL_PADDING
      expected_max = max_width - internal_padding - border_total_padding

      expect(PdfGeneratorService::PositionCalculator).to receive(:fit_dimensions)
        .with(
          image.width,
          image.height,
          expected_max,
          PdfGeneratorService::Configuration::SIGNATURE_HEIGHT
        )

      described_class.send(:calculate_signature_dimensions, image, max_width)
    end
  end

  describe ".calculate_signature_positions" do
    let(:x_offset) { 50 }
    let(:available_width) { 300 }
    let(:width) { 150 }
    let(:height) { 100 }
    let(:border_padding) { 5 }
    let(:content_top_y) { 400 }

    it "calculates correct positions" do
      result = described_class.send(:calculate_signature_positions,
        x_offset, available_width, width, height,
        border_padding, content_top_y)

      expect(result).to include(
        x_position: x_offset + available_width - width - (border_padding * 2) + border_padding,
        y_position: content_top_y,
        border_x: x_offset + available_width - width - (border_padding * 2),
        border_y: content_top_y + border_padding,
        border_width: width + (border_padding * 2),
        border_height: height + (border_padding * 2),
        width: width,
        height: height,
        border_padding: border_padding
      )
    end
  end

  describe ".draw_signature_border" do
    let(:positions) do
      {
        border_x: 100,
        border_y: 200,
        border_width: 150,
        border_height: 100
      }
    end

    it "sets stroke color and line width" do
      expect(pdf).to receive(:stroke_color).with("CCCCCC")
      expect(pdf).to receive(:line_width=).with(1)
      described_class.send(:draw_signature_border, pdf, positions)
    end

    it "draws rectangle at correct position" do
      expect(pdf).to receive(:stroke_rectangle).with(
        [positions[:border_x], positions[:border_y]],
        positions[:border_width],
        positions[:border_height]
      )
      described_class.send(:draw_signature_border, pdf, positions)
    end
  end

  describe ".render_signature_image" do
    let(:image) { double("image") }
    let(:signature_attachment) { double("attachment") }
    let(:positions) do
      {
        x_position: 110,
        y_position: 200,
        width: 140,
        height: 90
      }
    end

    it "renders processed image with correct parameters" do
      expect(PdfGeneratorService::ImageProcessor)
        .to receive(:render_processed_image).with(
          pdf, image,
          positions[:x_position],
          positions[:y_position],
          positions[:width],
          positions[:height],
          signature_attachment
        )
      described_class.send(:render_signature_image, pdf, image,
        positions, signature_attachment)
    end
  end

  describe ".render_signature_caption" do
    let(:positions) do
      {
        y_position: 200,
        height: 90,
        border_padding: 5,
        border_x: 100,
        border_width: 150
      }
    end

    it "renders caption at correct position" do
      expected_y = positions[:y_position] - positions[:height] -
        positions[:border_padding] - 4

      expect(pdf).to receive(:text_box).with(
        I18n.t("pdf.signature.caption"),
        at: [positions[:border_x], expected_y],
        width: positions[:border_width],
        height: 20,
        size: PdfGeneratorService::Configuration::DISCLAIMER_TEXT_SIZE,
        align: :center,
        valign: :top
      )
      described_class.send(:render_signature_caption, pdf, positions)
    end
  end
end