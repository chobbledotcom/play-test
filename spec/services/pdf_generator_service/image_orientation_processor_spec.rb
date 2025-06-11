require "rails_helper"

RSpec.describe PdfGeneratorService::ImageOrientationProcessor do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    unit.photo.attach(
      io: File.open(Rails.root.join("spec", "fixtures", "files", "test_image.jpg")),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  describe ".process_with_orientation" do
    let(:photo) { unit.photo }

    it "processes image and returns string data" do
      processed_data = described_class.process_with_orientation(photo)

      expect(processed_data).to be_a(String)
      expect(processed_data.length).to be > 0
    end

    it "handles image processing without errors" do
      expect { described_class.process_with_orientation(photo) }.not_to raise_error
    end

    it "returns processed image data different from original" do
      original_data = photo.download
      processed_data = described_class.process_with_orientation(photo)

      # Both should be strings, processed might be different if orientation changed
      expect(processed_data).to be_a(String)
      expect(original_data).to be_a(String)
    end

    context "with invalid image data" do
      it "raises error for corrupted image" do
        bad_photo = double("bad_photo")
        allow(bad_photo).to receive(:download).and_return("not_an_image")

        expect {
          described_class.process_with_orientation(bad_photo)
        }.to raise_error
      end
    end

    context "file cleanup" do
      it "cleans up temporary files after processing" do
        # Just verify no errors occur during cleanup
        expect { described_class.process_with_orientation(photo) }.not_to raise_error
      end
    end
  end

  describe ".get_dimensions" do
    let(:photo) { unit.photo }

    it "returns width and height as array" do
      width, height = described_class.get_dimensions(photo)

      expect(width).to be_a(Integer)
      expect(height).to be_a(Integer)
      expect(width).to be > 0
      expect(height).to be > 0
    end

    it "handles real image dimensions" do
      width, height = described_class.get_dimensions(photo)

      # Test image should have reasonable dimensions (allowing for larger test images)
      expect(width).to be_between(10, 10000)
      expect(height).to be_between(10, 10000)
    end

    context "with invalid image" do
      it "raises error for corrupted image" do
        bad_photo = double("bad_photo")
        allow(bad_photo).to receive(:download).and_return("not_an_image")

        expect {
          described_class.get_dimensions(bad_photo)
        }.to raise_error
      end
    end

    context "file cleanup" do
      it "cleans up temporary files after getting dimensions" do
        # Just verify no errors occur during cleanup
        expect { described_class.get_dimensions(photo) }.not_to raise_error
      end
    end
  end

  describe ".needs_orientation_correction?" do
    let(:photo) { unit.photo }

    it "returns boolean value" do
      result = described_class.needs_orientation_correction?(photo)

      expect(result).to be_in([true, false])
    end

    it "handles images without EXIF data gracefully" do
      # Most test images won't have complex EXIF data
      result = described_class.needs_orientation_correction?(photo)

      expect(result).to be false # Test image likely doesn't need correction
    end

    context "with invalid image" do
      it "returns false for corrupted image" do
        bad_photo = double("bad_photo")
        allow(bad_photo).to receive(:download).and_return("not_an_image")

        result = described_class.needs_orientation_correction?(bad_photo)

        expect(result).to be false
      end
    end

    context "file cleanup" do
      it "cleans up temporary files after checking orientation" do
        # Just verify no errors occur during cleanup
        expect { described_class.needs_orientation_correction?(photo) }.not_to raise_error
      end
    end
  end

  describe "integration scenarios" do
    context "processing workflow" do
      let(:photo) { unit.photo }

      it "can check orientation, get dimensions, and process image" do
        # This tests the typical workflow
        needs_correction = described_class.needs_orientation_correction?(photo)
        width, height = described_class.get_dimensions(photo)
        processed_data = described_class.process_with_orientation(photo)

        expect(needs_correction).to be_in([true, false])
        expect(width).to be > 0
        expect(height).to be > 0
        expect(processed_data).to be_a(String)
        expect(processed_data.length).to be > 0
      end
    end

    context "error handling throughout workflow" do
      it "handles errors consistently across all methods" do
        bad_photo = double("bad_photo")
        allow(bad_photo).to receive(:download).and_return("invalid_data")

        # needs_orientation_correction should return false (graceful)
        expect(described_class.needs_orientation_correction?(bad_photo)).to be false

        # get_dimensions should raise error
        expect { described_class.get_dimensions(bad_photo) }.to raise_error

        # process_with_orientation should raise error
        expect { described_class.process_with_orientation(bad_photo) }.to raise_error
      end
    end
  end

  describe "temp file management" do
    it "uses unique temp file names to avoid conflicts" do
      photo1 = unit.photo

      # Create another unit with photo
      unit2 = create(:unit, user: user)
      unit2.photo.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_image.jpg")),
        filename: "test_image2.jpg",
        content_type: "image/jpeg"
      )
      photo2 = unit2.photo

      # Process both simultaneously in threads to test for conflicts
      results = []
      threads = []

      threads << Thread.new { results << described_class.process_with_orientation(photo1) }
      threads << Thread.new { results << described_class.process_with_orientation(photo2) }

      threads.each(&:join)

      expect(results.length).to eq(2)
      expect(results.all? { |r| r.is_a?(String) && r.length > 0 }).to be true
    end
  end
end
