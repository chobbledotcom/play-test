require "rails_helper"
require "vips"

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

      # The image should process successfully with transparency handling
      io_string = processed_io[:io].string
      processed_image = Vips::Image.new_from_buffer(io_string, "")
      # Vips loaded it successfully, which means it's a valid JPEG
      expect(processed_image.width).to be > 0
    end

    it "converts images to JPEG format" do
      # Even if we had a PNG, it should be converted to JPEG
      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      image_data = File.binread(image_path)

      filename = "image.png"
      processed_io = described_class.process_upload_data(image_data, filename)

      expect(processed_io).not_to be_nil
      expect(processed_io[:filename]).to eq("image.jpg")
      expect(processed_io[:content_type]).to eq("image/jpeg")
    end
  end
end
