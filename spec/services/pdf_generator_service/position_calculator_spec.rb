require "rails_helper"

RSpec.describe PdfGeneratorService::PositionCalculator do
  # Use real configuration values for testing
  let(:qr_code_size) { PdfGeneratorService::Configuration::QR_CODE_SIZE }
  let(:qr_code_margin) { PdfGeneratorService::Configuration::QR_CODE_MARGIN }
  let(:qr_code_bottom_offset) { PdfGeneratorService::Configuration::QR_CODE_BOTTOM_OFFSET }
  let(:unit_photo_x_offset) { PdfGeneratorService::Configuration::UNIT_PHOTO_X_OFFSET }
  let(:unit_photo_width) { PdfGeneratorService::Configuration::UNIT_PHOTO_WIDTH }
  let(:unit_photo_height) { PdfGeneratorService::Configuration::UNIT_PHOTO_HEIGHT }

  describe ".qr_code_position" do
    context "with standard PDF width" do
      let(:pdf_width) { 500 }

      it "calculates QR code position in bottom right corner" do
        x, y = described_class.qr_code_position(pdf_width)

        expected_x = pdf_width - qr_code_size - qr_code_margin
        expected_y = qr_code_bottom_offset + qr_code_size

        expect(x).to eq(expected_x)
        expect(y).to eq(expected_y)
      end
    end

    context "with narrow PDF width" do
      let(:pdf_width) { 200 }

      it "handles narrow PDFs" do
        x, y = described_class.qr_code_position(pdf_width)

        expected_x = pdf_width - qr_code_size - qr_code_margin
        expected_y = qr_code_bottom_offset + qr_code_size

        expect(x).to eq(expected_x)
        expect(y).to eq(expected_y)
      end

      it "may result in negative x for very narrow PDFs" do
        very_narrow_width = qr_code_size + qr_code_margin - 10
        x, _y = described_class.qr_code_position(very_narrow_width)

        expect(x).to be < 0
      end
    end

    context "with wide PDF width" do
      let(:pdf_width) { 1000 }

      it "handles wide PDFs" do
        x, y = described_class.qr_code_position(pdf_width)

        expected_x = pdf_width - qr_code_size - qr_code_margin
        expected_y = qr_code_bottom_offset + qr_code_size

        expect(x).to eq(expected_x)
        expect(y).to eq(expected_y)
      end
    end
  end

  describe ".photo_footer_position" do
    let(:qr_x) { 400 }
    let(:qr_y) { 100 }

    context "with default photo size" do
      it "aligns photo with QR code bottom-right corner" do
        photo_x, photo_y = described_class.photo_footer_position(qr_x, qr_y)

        photo_size = qr_code_size * 2
        expected_photo_x = qr_x + qr_code_size - photo_size
        expected_photo_y = qr_y - qr_code_size + photo_size

        expect(photo_x).to eq(expected_photo_x)
        expect(photo_y).to eq(expected_photo_y)
      end
    end

    context "with custom photo size" do
      let(:custom_photo_size) { 150 }

      it "uses custom photo size for positioning" do
        photo_x, photo_y = described_class.photo_footer_position(qr_x, qr_y, custom_photo_size)

        expected_photo_x = qr_x + qr_code_size - custom_photo_size
        expected_photo_y = qr_y - qr_code_size + custom_photo_size

        expect(photo_x).to eq(expected_photo_x)
        expect(photo_y).to eq(expected_photo_y)
      end
    end

    context "alignment verification" do
      it "ensures photo right edge aligns with QR right edge" do
        photo_width = qr_code_size * 2
        photo_height = qr_code_size * 2
        photo_x, _photo_y = described_class.photo_footer_position(qr_x, qr_y, photo_width, photo_height)

        photo_right_edge = photo_x + photo_width
        qr_right_edge = qr_x + qr_code_size

        expect(photo_right_edge).to eq(qr_right_edge)
      end

      it "ensures photo bottom edge aligns with QR bottom edge" do
        photo_width = qr_code_size * 2
        photo_height = qr_code_size * 2
        _photo_x, photo_y = described_class.photo_footer_position(qr_x, qr_y, photo_width, photo_height)

        photo_bottom_edge = photo_y - photo_height
        qr_bottom_edge = qr_y - qr_code_size

        expect(photo_bottom_edge).to eq(qr_bottom_edge)
      end

      it "works with different aspect ratios" do
        # Portrait photo: narrow width, tall height
        photo_width = qr_code_size * 2
        photo_height = qr_code_size * 3 # Taller portrait
        photo_x, photo_y = described_class.photo_footer_position(qr_x, qr_y, photo_width, photo_height)

        # Right edges should still align
        photo_right_edge = photo_x + photo_width
        qr_right_edge = qr_x + qr_code_size
        expect(photo_right_edge).to eq(qr_right_edge)

        # Bottom edges should still align
        photo_bottom_edge = photo_y - photo_height
        qr_bottom_edge = qr_y - qr_code_size
        expect(photo_bottom_edge).to eq(qr_bottom_edge)
      end
    end
  end

  describe ".header_photo_position" do
    let(:pdf_width) { 500 }
    let(:pdf_cursor) { 700 }

    context "with default positioning" do
      it "calculates top right corner position" do
        x_pos, y_pos = described_class.header_photo_position(pdf_width, pdf_cursor)

        expected_x = pdf_width - unit_photo_x_offset
        expected_y = pdf_cursor

        expect(x_pos).to eq(expected_x)
        expect(y_pos).to eq(expected_y)
      end
    end

    context "with custom x position" do
      let(:custom_x) { 300 }

      it "uses custom x position" do
        x_pos, y_pos = described_class.header_photo_position(pdf_width, pdf_cursor, custom_x)

        expect(x_pos).to eq(custom_x)
        expect(y_pos).to eq(pdf_cursor)
      end
    end

    context "with custom y position" do
      let(:custom_y) { 600 }

      it "uses custom y position" do
        x_pos, y_pos = described_class.header_photo_position(pdf_width, pdf_cursor, nil, custom_y)

        expected_x = pdf_width - unit_photo_x_offset
        expect(x_pos).to eq(expected_x)
        expect(y_pos).to eq(custom_y)
      end
    end

    context "with both custom positions" do
      let(:custom_x) { 250 }
      let(:custom_y) { 550 }

      it "uses both custom positions" do
        x_pos, y_pos = described_class.header_photo_position(pdf_width, pdf_cursor, custom_x, custom_y)

        expect(x_pos).to eq(custom_x)
        expect(y_pos).to eq(custom_y)
      end
    end
  end

  describe ".footer_photo_dimensions" do
    context "with landscape image" do
      it "calculates dimensions maintaining aspect ratio" do
        # 1600x1200 landscape image
        width, height = described_class.footer_photo_dimensions(1600, 1200)

        expected_width = qr_code_size * 2
        expected_height = (expected_width / (1600.0 / 1200.0)).round # 160 / 1.333 = 120

        expect(width).to eq(expected_width)
        expect(height).to eq(expected_height)
      end
    end

    context "with portrait image" do
      it "calculates dimensions maintaining aspect ratio" do
        # 1200x1600 portrait image (post-EXIF rotation)
        width, height = described_class.footer_photo_dimensions(1200, 1600)

        expected_width = qr_code_size * 2
        expected_height = (expected_width / (1200.0 / 1600.0)).round # 160 / 0.75 = 213

        expect(width).to eq(expected_width)
        expect(height).to eq(expected_height)
      end
    end

    context "with square image" do
      it "calculates square dimensions" do
        width, height = described_class.footer_photo_dimensions(1000, 1000)

        expected_size = qr_code_size * 2

        expect(width).to eq(expected_size)
        expect(height).to eq(expected_size)
      end
    end

    context "with zero dimensions" do
      it "returns square fallback" do
        width, height = described_class.footer_photo_dimensions(0, 0)

        expected_size = qr_code_size * 2

        expect(width).to eq(expected_size)
        expect(height).to eq(expected_size)
      end
    end
  end

  describe ".qr_code_dimensions" do
    it "returns QR code width and height" do
      width, height = described_class.qr_code_dimensions

      expect(width).to eq(qr_code_size)
      expect(height).to eq(qr_code_size)
    end
  end

  describe ".header_photo_dimensions" do
    it "fits image within header photo bounds maintaining aspect ratio" do
      # Test with image that fits within bounds
      width, height = described_class.header_photo_dimensions(100, 80)

      expect(width).to eq(100)
      expect(height).to eq(80)
    end

    it "scales down large image maintaining aspect ratio" do
      # Test with image larger than bounds
      width, height = described_class.header_photo_dimensions(200, 160)

      # Should scale down proportionally to fit within unit_photo_width x unit_photo_height
      expect(width).to be <= unit_photo_width
      expect(height).to be <= unit_photo_height

      # Check aspect ratio is maintained (allowing for rounding)
      original_ratio = 200.0 / 160.0
      fitted_ratio = width.to_f / height.to_f
      expect(fitted_ratio).to be_within(0.01).of(original_ratio)
    end
  end

  describe ".default_header_photo_dimensions" do
    it "returns default header photo width and height" do
      width, height = described_class.default_header_photo_dimensions

      expect(width).to eq(unit_photo_width)
      expect(height).to eq(unit_photo_height)
    end
  end

  describe ".within_bounds?" do
    let(:pdf_width) { 500 }
    let(:pdf_height) { 700 }

    context "when element is within bounds" do
      it "returns true for element in top-left corner" do
        result = described_class.within_bounds?(0, 0, 50, 50, pdf_width, pdf_height)

        expect(result).to be true
      end

      it "returns true for element in center" do
        result = described_class.within_bounds?(200, 300, 100, 100, pdf_width, pdf_height)

        expect(result).to be true
      end

      it "returns true for element touching right and bottom edges" do
        result = described_class.within_bounds?(400, 600, 100, 100, pdf_width, pdf_height)

        expect(result).to be true
      end
    end

    context "when element exceeds bounds" do
      it "returns false when x position is negative" do
        result = described_class.within_bounds?(-10, 0, 50, 50, pdf_width, pdf_height)

        expect(result).to be false
      end

      it "returns false when y position is negative" do
        result = described_class.within_bounds?(0, -10, 50, 50, pdf_width, pdf_height)

        expect(result).to be false
      end

      it "returns false when width exceeds right boundary" do
        result = described_class.within_bounds?(450, 300, 100, 100, pdf_width, pdf_height)

        expect(result).to be false
      end

      it "returns false when height exceeds bottom boundary" do
        result = described_class.within_bounds?(200, 650, 100, 100, pdf_width, pdf_height)

        expect(result).to be false
      end
    end

    context "edge cases" do
      it "returns true when element exactly fits bounds" do
        result = described_class.within_bounds?(0, 0, pdf_width, pdf_height, pdf_width, pdf_height)

        expect(result).to be true
      end

      it "returns false when element is one pixel too wide" do
        result = described_class.within_bounds?(0, 0, pdf_width + 1, pdf_height, pdf_width, pdf_height)

        expect(result).to be false
      end
    end
  end

  describe ".calculate_aspect_ratio" do
    context "with standard dimensions" do
      it "calculates aspect ratio for landscape image" do
        ratio = described_class.calculate_aspect_ratio(800, 600)

        expect(ratio).to be_within(0.001).of(1.333)
      end

      it "calculates aspect ratio for portrait image" do
        ratio = described_class.calculate_aspect_ratio(600, 800)

        expect(ratio).to be_within(0.001).of(0.75)
      end

      it "calculates aspect ratio for square image" do
        ratio = described_class.calculate_aspect_ratio(500, 500)

        expect(ratio).to eq(1.0)
      end
    end

    context "with edge cases" do
      it "returns 1.0 when height is zero" do
        ratio = described_class.calculate_aspect_ratio(800, 0)

        expect(ratio).to eq(1.0)
      end

      it "handles very wide images" do
        ratio = described_class.calculate_aspect_ratio(1000, 100)

        expect(ratio).to eq(10.0)
      end

      it "handles very tall images" do
        ratio = described_class.calculate_aspect_ratio(100, 1000)

        expect(ratio).to eq(0.1)
      end
    end
  end

  describe ".fit_dimensions" do
    context "when original fits within constraints" do
      it "returns original dimensions when smaller than constraints" do
        fitted_width, fitted_height = described_class.fit_dimensions(300, 200, 400, 300)

        expect(fitted_width).to eq(300)
        expect(fitted_height).to eq(200)
      end
    end

    context "when original exceeds constraints" do
      it "scales down by width when width is limiting factor" do
        fitted_width, fitted_height = described_class.fit_dimensions(800, 400, 400, 600)

        expect(fitted_width).to eq(400)
        expect(fitted_height).to eq(200)
      end

      it "scales down by height when height is limiting factor" do
        fitted_width, fitted_height = described_class.fit_dimensions(400, 800, 600, 400)

        expect(fitted_width).to eq(200)
        expect(fitted_height).to eq(400)
      end

      it "maintains aspect ratio when scaling" do
        original_ratio = 800.0 / 600.0
        fitted_width, fitted_height = described_class.fit_dimensions(800, 600, 400, 300)
        fitted_ratio = fitted_width.to_f / fitted_height.to_f

        expect(fitted_ratio).to be_within(0.001).of(original_ratio)
      end
    end

    context "with edge cases" do
      it "handles zero width gracefully" do
        fitted_width, fitted_height = described_class.fit_dimensions(0, 200, 100, 100)

        expect(fitted_width).to eq(100)
        expect(fitted_height).to eq(100)
      end

      it "handles zero height gracefully" do
        fitted_width, fitted_height = described_class.fit_dimensions(200, 0, 100, 100)

        expect(fitted_width).to eq(100)
        expect(fitted_height).to eq(100)
      end

      it "handles perfect square fit" do
        fitted_width, fitted_height = described_class.fit_dimensions(200, 200, 100, 100)

        expect(fitted_width).to eq(100)
        expect(fitted_height).to eq(100)
      end
    end

    context "real world scenarios" do
      it "handles typical photo scaling (4:3 aspect ratio)" do
        # Original: 1200x900, fit into 300x200
        fitted_width, fitted_height = described_class.fit_dimensions(1200, 900, 300, 200)

        expect(fitted_width).to eq(267) # Limited by height: 200 * (4/3) = 266.67 → 267
        expect(fitted_height).to eq(200)
      end

      it "handles wide banner scaling (16:9 aspect ratio)" do
        # Original: 1920x1080, fit into 400x300
        fitted_width, fitted_height = described_class.fit_dimensions(1920, 1080, 400, 300)

        expect(fitted_width).to eq(400)
        expect(fitted_height).to eq(225) # 400 / (16/9) = 225
      end
    end
  end
end
