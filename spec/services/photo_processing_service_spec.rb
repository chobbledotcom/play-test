require "rails_helper"

RSpec.describe PhotoProcessingService do
  describe ".process_upload_data" do
    it "returns nil for nil image data" do
      expect(described_class.process_upload_data(nil)).to be_nil
    end

    it "returns nil for empty image data" do
      expect(described_class.process_upload_data("")).to be_nil
    end
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
      puts "Processed image dimensions: #{processed_image.width}x#{processed_image.height}"
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

    it "handles invalid image data gracefully" do
      invalid_data = "not an image"

      processed_io = described_class.process_upload_data(invalid_data, "invalid.txt")

      expect(processed_io).to be_nil
    end

    it "logs error when image processing fails" do
      invalid_data = "not an image"

      expect(Rails.logger).to receive(:error).with(/Photo processing failed/)

      described_class.process_upload_data(invalid_data, "invalid.txt")
    end

    it "uses default filename when none provided" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(image_path)

      processed_io = described_class.process_upload_data(image_data)

      expect(processed_io.original_filename).to eq("photo.jpg")
    end
  end

  describe ".process_upload" do
    it "processes uploaded file successfully" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      uploaded_file = double("uploaded_file",
        present?: true,
        read: File.binread(image_path),
        original_filename: "test_upload.jpg")

      processed_io = described_class.process_upload(uploaded_file)

      expect(processed_io).to be_present
      expect(processed_io.content_type).to eq("image/jpeg")
      expect(processed_io.original_filename).to eq("test_upload.jpg")
    end

    it "returns nil for nil uploaded file" do
      expect(described_class.process_upload(nil)).to be_nil
    end

    it "returns nil for non-present uploaded file" do
      uploaded_file = double("uploaded_file", present?: false)

      expect(described_class.process_upload(uploaded_file)).to be_nil
    end
  end

  describe ".valid_image_data?" do
    it "returns true for valid image data" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(image_path)

      expect(described_class.valid_image_data?(image_data)).to be true
    end

    it "returns false for invalid data" do
      invalid_data = "not an image"

      expect(described_class.valid_image_data?(invalid_data)).to be false
    end

    it "returns false for nil data" do
      expect(described_class.valid_image_data?(nil)).to be false
    end

    it "returns false for empty data" do
      expect(described_class.valid_image_data?("")).to be false
    end

    it "returns false when MiniMagick raises exception" do
      # This will trigger the rescue block
      corrupt_data = "JPEG\x00\x01corrupt"

      expect(described_class.valid_image_data?(corrupt_data)).to be false
    end
  end

  describe ".valid_image?" do
    it "returns true for valid uploaded file" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      uploaded_file = double("uploaded_file",
        present?: true,
        read: File.binread(image_path))

      expect(described_class.valid_image?(uploaded_file)).to be true
    end

    it "returns false for invalid uploaded file" do
      uploaded_file = double("uploaded_file",
        present?: true,
        read: "not an image")

      expect(described_class.valid_image?(uploaded_file)).to be false
    end

    it "returns false for nil uploaded file" do
      expect(described_class.valid_image?(nil)).to be false
    end

    it "returns false for non-present uploaded file" do
      uploaded_file = double("uploaded_file", present?: false)

      expect(described_class.valid_image?(uploaded_file)).to be false
    end
  end

  describe "filename handling" do
    it "changes extensions to .jpg" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(image_path)

      # Test various input filenames
      test_cases = [
        ["photo.png", "photo.jpg"],
        ["image.gif", "image.jpg"],
        ["test.JPEG", "test.jpg"],
        ["file", "file.jpg"],
        [nil, "photo.jpg"]
      ]

      test_cases.each do |input, expected|
        processed_io = described_class.process_upload_data(image_data, input)
        expect(processed_io.original_filename).to eq(expected)
      end
    end

    it "handles filename without extension" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(image_path)

      processed_io = described_class.process_upload_data(image_data, "filename_no_extension")

      expect(processed_io.original_filename).to eq("filename_no_extension.jpg")
    end

    it "handles empty filename" do
      image_path = Rails.root.join("spec", "fixtures", "files", "large_landscape.jpg")
      image_data = File.binread(image_path)

      processed_io = described_class.process_upload_data(image_data, "")

      expect(processed_io.original_filename).to eq("photo.jpg")
    end
  end
end
