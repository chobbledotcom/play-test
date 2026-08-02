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

    it "applies EXIF orientation for rotated photos" do
      # Orientation 6 (rotate 90 CW) has raw pixels 100x60
      # but should become 60x100 after autorot
      fixture = "spec/fixtures/files/orientation_6_rotate_90_cw.jpg"
      image_data = Rails.root.join(fixture).binread

      result = described_class.process_upload_data(image_data, "rotated.jpg")
      image = Vips::Image.new_from_buffer(result[:io].read, "")

      expect(image.width).to eq(60)
      expect(image.height).to eq(100)
    end

    it "preserves dimensions for normally oriented photos" do
      # Orientation 1 (normal) has raw pixels 100x60
      # and should stay 100x60 after processing
      fixture = "spec/fixtures/files/orientation_1_normal.jpg"
      image_data = Rails.root.join(fixture).binread

      result = described_class.process_upload_data(image_data, "normal.jpg")
      image = Vips::Image.new_from_buffer(result[:io].read, "")

      expect(image.width).to eq(100)
      expect(image.height).to eq(60)
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

    it "rejects data above the byte limit before decoding" do
      oversized_data = instance_double(
        String,
        blank?: false,
        bytesize: described_class::MAX_UPLOAD_BYTES + 1
      )
      expect(Vips::Image).not_to receive(:new_from_buffer)

      expect(described_class.valid_image_data?(oversized_data)).to be false
    end
  end

  describe ".upload_within_size_limit?" do
    it "accepts files at the upload limit" do
      upload = Struct.new(:size).new(described_class::MAX_UPLOAD_BYTES)

      expect(described_class.upload_within_size_limit?(upload)).to be true
    end

    it "rejects files above the upload limit without reading them" do
      upload = Struct.new(:size).new(described_class::MAX_UPLOAD_BYTES + 1)

      expect(described_class.upload_within_size_limit?(upload)).to be false
    end

    it "rejects unsupported uploads without a size" do
      upload = Object.new

      expect(described_class.upload_within_size_limit?(upload)).to be false
    end
  end

  describe ".valid_image?" do
    it "validates tempfile-backed uploads without reading them into memory" do
      tempfile = instance_double(Tempfile, path: "/tmp/upload.jpg")
      upload = double(blank?: false, size: 1024, tempfile: tempfile)
      image = double(width: 100, height: 100)

      expect(Vips::Image).to receive(:new_from_file)
        .with("/tmp/upload.jpg", access: :sequential)
        .and_return(image)
      expect(upload).not_to receive(:read)

      expect(described_class.valid_image?(upload)).to be true
    end
  end

  describe ".acceptable_dimensions?" do
    define_method(:acceptable_dimensions?) do |width, height|
      image = double(width: width, height: height)
      described_class.send(:acceptable_dimensions?, image)
    end

    it "accepts each per-axis limit" do
      expect(acceptable_dimensions?(described_class::MAX_IMAGE_DIMENSION, 1)).to be true
      expect(acceptable_dimensions?(1, described_class::MAX_IMAGE_DIMENSION)).to be true
    end

    it "rejects one pixel over either per-axis limit" do
      over_limit = described_class::MAX_IMAGE_DIMENSION + 1

      expect(acceptable_dimensions?(over_limit, 1)).to be false
      expect(acceptable_dimensions?(1, over_limit)).to be false
    end

    it "accepts the total-pixel limit" do
      expect(acceptable_dimensions?(8_000, 5_000)).to be true
    end

    it "rejects values above the total-pixel limit" do
      expect(3_015 * 13_267).to eq(described_class::MAX_IMAGE_PIXELS + 5)
      expect(acceptable_dimensions?(3_015, 13_267)).to be false
    end
  end
end
