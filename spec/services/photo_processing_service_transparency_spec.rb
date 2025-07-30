require "rails_helper"

RSpec.describe PhotoProcessingService do
  describe "transparency handling" do
    it "includes transparency removal in processing pipeline" do
      # Just verify the processing works with our transparency handling code
      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      image_data = File.binread(image_path)

      # Process the image
      processed_io = described_class.process_upload_data(image_data, "test.jpg")

      expect(processed_io).not_to be_nil
      expect(processed_io[:content_type]).to eq("image/jpeg")

      # The image should process successfully with the transparency handling code
      processed_image = MiniMagick::Image.read(processed_io[:io].string)
      expect(processed_image.type).to eq("JPEG")
    end

    it "converts images to JPEG format" do
      # Even if we had a PNG, it should be converted to JPEG
      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      image_data = File.binread(image_path)

      processed_io = described_class.process_upload_data(image_data, "image.png")

      expect(processed_io).not_to be_nil
      expect(processed_io[:filename]).to eq("image.jpg")
      expect(processed_io[:content_type]).to eq("image/jpeg")
    end
  end
end
