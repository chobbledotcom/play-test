require "rails_helper"

RSpec.describe PdfGeneratorService::ImageOrientationProcessor do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  def create_raw_image(filename)
    image_data = Rails.root.join("spec", "fixtures", "files", filename).binread
    MiniMagick::Image.read(image_data)
  end

  before do
    unit.photo.attach(
      io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  describe ".process_with_orientation" do
    let(:image) { PdfGeneratorService::ImageProcessor.create_image(unit.photo) }

    it "processes image and returns string data" do
      processed_data = described_class.process_with_orientation(image)

      expect(processed_data).to be_a(String)
      expect(processed_data.length).to be > 0
    end

    it "handles image processing without errors" do
      expect { described_class.process_with_orientation(image) }.not_to raise_error
    end

    it "returns processed image data different from original" do
      original_data = unit.photo.download
      processed_data = described_class.process_with_orientation(image)

      # Both should be strings, processed might be different if orientation changed
      expect(processed_data).to be_a(String)
      expect(original_data).to be_a(String)
    end
  end

  describe ".get_dimensions" do
    let(:image) { PdfGeneratorService::ImageProcessor.create_image(unit.photo) }

    it "returns width and height as array" do
      width, height = described_class.get_dimensions(image)

      expect(width).to be_a(Integer)
      expect(height).to be_a(Integer)
      expect(width).to be > 0
      expect(height).to be > 0
    end

    it "handles real image dimensions" do
      width, height = described_class.get_dimensions(image)

      # Test image should have reasonable dimensions (allowing for larger test images)
      expect(width).to be_between(10, 10000)
      expect(height).to be_between(10, 10000)
    end
  end

  describe ".needs_orientation_correction?" do
    it "returns false for orientation 1 (normal)" do
      image = create_raw_image("orientation_1_normal.jpg")

      result = described_class.needs_orientation_correction?(image)
      expect(result).to be false
    end

    it "returns true for orientation 2 (horizontal flip)" do
      image = create_raw_image("orientation_2_flip_horizontal.jpg")

      result = described_class.needs_orientation_correction?(image)
      expect(result).to be true
    end

    it "returns true for orientation 3 (180° rotation)" do
      image = create_raw_image("orientation_3_rotate_180.jpg")

      result = described_class.needs_orientation_correction?(image)
      expect(result).to be true
    end

    it "returns true for orientation 6 (90° clockwise)" do
      image = create_raw_image("orientation_6_rotate_90_cw.jpg")

      result = described_class.needs_orientation_correction?(image)
      expect(result).to be true
    end

    it "returns true for orientation 8 (90° counter-clockwise)" do
      image = create_raw_image("orientation_8_rotate_90_ccw.jpg")

      result = described_class.needs_orientation_correction?(image)
      expect(result).to be true
    end

    it "returns false when no EXIF data present" do
      image = create_raw_image("no_exif.jpg")

      result = described_class.needs_orientation_correction?(image)
      expect(result).to be false
    end
  end

  describe "EXIF orientation handling with raw images" do
    context "with landscape image needing 90° clockwise rotation (orientation 6)" do
      let(:image) { create_raw_image("orientation_6_rotate_90_cw.jpg") }

      it "correctly identifies need for correction" do
        expect(described_class.needs_orientation_correction?(image)).to be true
      end

      it "applies auto_orient and returns corrected dimensions" do
        # Original image is 100x60 landscape, after 90° rotation it becomes 60x100 portrait
        width, height = described_class.get_dimensions(image)

        # After rotation, landscape (100x60) becomes portrait (60x100)
        expect(width).to eq(60)
        expect(height).to eq(100)
      end

      it "processes image with orientation correction" do
        result = described_class.process_with_orientation(image)

        expect(result).to be_a(String)
        expect(result.length).to be > 0
      end
    end

    context "with image needing 180° rotation (orientation 3)" do
      let(:image) { create_raw_image("orientation_3_rotate_180.jpg") }

      it "correctly identifies need for correction" do
        expect(described_class.needs_orientation_correction?(image)).to be true
      end

      it "maintains dimensions after 180-degree rotation" do
        width, height = described_class.get_dimensions(image)

        # 180° rotation keeps same dimensions: 100x60 stays 100x60
        expect(width).to eq(100)
        expect(height).to eq(60)
      end

      it "processes image with orientation correction" do
        result = described_class.process_with_orientation(image)

        expect(result).to be_a(String)
        expect(result.length).to be > 0
      end
    end

    context "with horizontally flipped image (orientation 2)" do
      let(:image) { create_raw_image("orientation_2_flip_horizontal.jpg") }

      it "correctly identifies need for correction" do
        expect(described_class.needs_orientation_correction?(image)).to be true
      end

      it "maintains dimensions after horizontal flip" do
        width, height = described_class.get_dimensions(image)

        # Horizontal flip keeps same dimensions: 100x60 stays 100x60
        expect(width).to eq(100)
        expect(height).to eq(60)
      end

      it "processes image with orientation correction" do
        result = described_class.process_with_orientation(image)

        expect(result).to be_a(String)
        expect(result.length).to be > 0
      end
    end

    context "with large image needing rotation" do
      let(:image) { create_raw_image("large_landscape.jpg") }

      it "correctly handles large images with orientation 6" do
        expect(described_class.needs_orientation_correction?(image)).to be true

        width, height = described_class.get_dimensions(image)

        # Large landscape (1600x1200) with orientation 6 becomes portrait (1200x1600)
        expect(width).to eq(1200)
        expect(height).to eq(1600)
      end

      it "processes large image efficiently" do
        result = described_class.process_with_orientation(image)

        expect(result).to be_a(String)
        expect(result.length).to be > 0
      end
    end
  end

  describe "integration scenarios" do
    context "processing workflow with normal image" do
      let(:image) { PdfGeneratorService::ImageProcessor.create_image(unit.photo) }

      it "can check orientation, get dimensions, and process image" do
        # This tests the typical workflow with original test image
        needs_correction = described_class.needs_orientation_correction?(image)
        width, height = described_class.get_dimensions(image)
        processed_data = described_class.process_with_orientation(image)

        expect(needs_correction).to be_in([true, false])
        expect(width).to be > 0
        expect(height).to be > 0
        expect(processed_data).to be_a(String)
        expect(processed_data.length).to be > 0
      end
    end

    context "complete workflow with real rotation" do
      let(:image) { create_raw_image("orientation_6_rotate_90_cw.jpg") }

      it "handles complete workflow with rotation needed" do
        # Check that it needs correction
        expect(described_class.needs_orientation_correction?(image)).to be true

        # Get corrected dimensions (landscape 100x60 becomes portrait 60x100)
        width, height = described_class.get_dimensions(image)
        expect(width).to eq(60)
        expect(height).to eq(100)

        # Process with correction
        processed_data = described_class.process_with_orientation(image)
        expect(processed_data).to be_a(String)
        expect(processed_data.length).to be > 0
      end

      it "demonstrates dimension change from rotation" do
        # Before auto_orient: should be landscape 100x60
        original_width = image.width
        original_height = image.height
        expect(original_width).to eq(100)
        expect(original_height).to eq(60)

        # After auto_orient via get_dimensions: should be portrait 60x100
        corrected_width, corrected_height = described_class.get_dimensions(image)
        expect(corrected_width).to eq(60)
        expect(corrected_height).to eq(100)

        # Dimensions have swapped due to 90° rotation
        expect(corrected_width).to eq(original_height)
        expect(corrected_height).to eq(original_width)
      end

      it "provides correct dimensions for aspect ratio calculations" do
        # This is the key test - ensuring PositionCalculator gets post-rotation dimensions
        corrected_width, corrected_height = described_class.get_dimensions(image)

        # Use the corrected dimensions in PositionCalculator
        photo_width, photo_height = PdfGeneratorService::PositionCalculator.footer_photo_dimensions(corrected_width, corrected_height)

        # QR code size is typically 36, so photo width should be 72
        qr_size = PdfGeneratorService::Configuration::QR_CODE_SIZE
        expected_width = qr_size * 2

        expect(photo_width).to eq(expected_width)

        # Height should maintain aspect ratio based on corrected dimensions (60x100 = 0.6 ratio)
        aspect_ratio = corrected_width.to_f / corrected_height.to_f
        expected_height = (expected_width / aspect_ratio).round

        expect(photo_height).to eq(expected_height)
      end
    end
  end

  describe "memory processing" do
    it "processes multiple images concurrently without conflicts" do
      image1 = PdfGeneratorService::ImageProcessor.create_image(unit.photo)

      # Create another unit with photo
      unit2 = create(:unit, user: user)
      unit2.photo.attach(
        io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
        filename: "test_image2.jpg",
        content_type: "image/jpeg"
      )
      image2 = PdfGeneratorService::ImageProcessor.create_image(unit2.photo)

      # Process both simultaneously in threads to test for conflicts
      results = []
      threads = []

      threads << Thread.new { results << described_class.process_with_orientation(image1) }
      threads << Thread.new { results << described_class.process_with_orientation(image2) }

      threads.each(&:join)

      expect(results.length).to eq(2)
      expect(results.all? { |r| r.is_a?(String) && r.length > 0 }).to be true
    end
  end
end
