# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::ImageOrientationProcessor do
  def create_raw_image(filename)
    image_data = Rails.root.join("spec", "fixtures", "files", filename).binread
    MiniMagick::Image.read(image_data)
  end

  describe ".needs_orientation_correction?" do
    it "returns false for orientation 1 (normal)" do
      image = create_raw_image("orientation_1_normal.jpg")
      expect(described_class.needs_orientation_correction?(image)).to be false
    end

    it "returns true for orientations that need correction" do
      image = create_raw_image("orientation_6_rotate_90_cw.jpg")
      expect(described_class.needs_orientation_correction?(image)).to be true
    end

    it "returns false when no EXIF data present" do
      image = create_raw_image("no_exif.jpg")
      expect(described_class.needs_orientation_correction?(image)).to be false
    end
  end

  describe ".get_dimensions" do
    it "returns corrected dimensions after rotation" do
      image = create_raw_image("orientation_6_rotate_90_cw.jpg")
      width, height = described_class.get_dimensions(image)

      # Landscape (100x60) becomes portrait (60x100) after 90° rotation
      expect(width).to eq(60)
      expect(height).to eq(100)
    end

    it "maintains dimensions for 180° rotation" do
      image = create_raw_image("orientation_3_rotate_180.jpg")
      width, height = described_class.get_dimensions(image)

      expect(width).to eq(100)
      expect(height).to eq(60)
    end
  end

  describe ".process_with_orientation" do
    it "processes image and returns blob data" do
      image = create_raw_image("orientation_6_rotate_90_cw.jpg")
      result = described_class.process_with_orientation(image)

      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end
  end
end
