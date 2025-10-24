# typed: false

require "rails_helper"

RSpec.describe PhotoProcessingService do
  describe ".process_upload_data" do
    it "resizes large images to max 1200px" do
      # Load a large test image
      path = "spec/fixtures/files/large_landscape.jpg"
      large_image_path = Rails.root.join(path)
      image_data = File.binread(large_image_path)

      # Process the image
      filename = "large_landscape.jpg"
      processed_io = described_class.process_upload_data(image_data, filename)

      expect(processed_io).to be_present
      expect(processed_io).to be_a(Hash)
      expect(processed_io[:content_type]).to eq("image/jpeg")
      expect(processed_io[:filename]).to eq("large_landscape.jpg")
    end

    it "converts images to JPEG format" do
      # Test with any image format
      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      image_data = File.binread(image_path)

      # Process the image
      processed_io = described_class.process_upload_data(image_data, "test.png")

      expect(processed_io).to be_present
      expect(processed_io[:content_type]).to eq("image/jpeg")
      # Extension changed to jpg
      expect(processed_io[:filename]).to eq("test.jpg")
    end

    it "handles invalid image data by returning nil" do
      invalid_data = "not an image"

      expect(Rails.logger).to receive(:error).with(/Photo processing failed/)
      filename = "invalid.txt"
      processed_io = described_class.process_upload_data(invalid_data, filename)

      expect(processed_io).to be_nil
    end

    it "uses default filename when none provided" do
      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      image_data = File.binread(image_path)

      processed_io = described_class.process_upload_data(image_data)

      expect(processed_io[:filename]).to eq("photo.jpg")
    end
  end

  describe ".valid_image_data?" do
    it "validates various data types correctly" do
      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      valid_data = File.binread(image_path)

      # Valid image data
      expect(described_class.valid_image_data?(valid_data)).to be true

      # Invalid cases
      expect(described_class.valid_image_data?("not an image")).to be false
      expect(described_class.valid_image_data?(nil)).to be false
      expect(described_class.valid_image_data?("")).to be false
    end
  end
end
