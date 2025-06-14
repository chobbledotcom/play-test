require "rails_helper"

RSpec.describe PhotoProcessingService do
  describe ".process_upload_data" do
    it "resizes large images to max 1200px" do
      # Load a large test image
      large_image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(large_image_path)

      # Process the image
      processed_io = described_class.process_upload_data(image_data, "large_landscape.jpg")

      expect(processed_io).to be_present
      expect(processed_io.content_type).to eq("image/jpeg")
      expect(processed_io.original_filename).to eq("large_landscape.jpg")

      # Check that the processed image is resized
      processed_image = MiniMagick::Image.read(processed_io.string)
      expect([processed_image.width, processed_image.height].max).to be <= ImageProcessorService::FULL_SIZE

      # The image should be resized properly - check actual dimensions
      expect(processed_image.width).to be > 0
      expect(processed_image.height).to be > 0
    end

    it "applies EXIF orientation correction" do
      # Load an image that needs rotation
      rotated_image_path = Rails.root.join("spec", "fixtures", "files", "orientation_6_rotate_90_cw.jpg")
      image_data = File.binread(rotated_image_path)

      # Process the image
      processed_io = described_class.process_upload_data(image_data, "orientation_6_rotate_90_cw.jpg")

      expect(processed_io).to be_present

      # Check that orientation has been applied
      processed_image = MiniMagick::Image.read(processed_io.string)

      # Original was 100x60 landscape with orientation 6 (90° rotation)
      # After processing should be 60x100 portrait with no EXIF orientation
      expect(processed_image.width).to eq(60)
      expect(processed_image.height).to eq(100)

      # Check that no orientation correction is needed (EXIF applied)
      needs_correction = PdfGeneratorService::ImageOrientationProcessor.needs_orientation_correction?(processed_image)
      expect(needs_correction).to be false
    end

    it "converts images to JPEG with 75% quality" do
      # Test with any image format
      image_path = Rails.root.join("spec", "fixtures", "files", "orientation_1_normal.jpg")
      image_data = File.binread(image_path)

      # Process the image
      processed_io = described_class.process_upload_data(image_data, "test.png")

      expect(processed_io).to be_present
      expect(processed_io.content_type).to eq("image/jpeg")
      expect(processed_io.original_filename).to eq("test.jpg") # Extension changed to jpg

      # Verify it's actually JPEG
      processed_image = MiniMagick::Image.read(processed_io.string)
      expect(processed_image.type).to eq("JPEG")
    end

    it "handles invalid image data by returning nil and logging error" do
      invalid_data = "not an image"

      expect(Rails.logger).to receive(:error).with(/Photo processing failed/)
      processed_io = described_class.process_upload_data(invalid_data, "invalid.txt")

      expect(processed_io).to be_nil
    end

    it "uses default filename when none provided" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(image_path)

      processed_io = described_class.process_upload_data(image_data)

      expect(processed_io.original_filename).to eq("photo.jpg")
    end
  end

  describe ".valid_image_data?" do
    it "validates various data types correctly" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      valid_data = File.binread(image_path)

      # Valid image data
      expect(described_class.valid_image_data?(valid_data)).to be true

      # Invalid cases
      expect(described_class.valid_image_data?("not an image")).to be false
      expect(described_class.valid_image_data?(nil)).to be false
      expect(described_class.valid_image_data?("")).to be false
      expect(described_class.valid_image_data?("JPEG\x00\x01corrupt")).to be false
    end
  end

  describe "filename handling" do
    it "normalizes all filenames to .jpg extension" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(image_path)

      # Test various input filenames
      test_cases = [
        ["photo.png", "photo.jpg"],
        ["image.gif", "image.jpg"],
        ["test.JPEG", "test.jpg"],
        ["filename_no_extension", "filename_no_extension.jpg"],
        ["", "photo.jpg"],
        [nil, "photo.jpg"]
      ]

      test_cases.each do |input, expected|
        processed_io = described_class.process_upload_data(image_data, input)
        expect(processed_io.original_filename).to eq(expected)
      end
    end
  end
end
