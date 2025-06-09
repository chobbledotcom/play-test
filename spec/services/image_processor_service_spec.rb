require "rails_helper"

RSpec.describe ImageProcessorService do
  let(:unit) { create(:unit) }
  let(:test_image_path) { Rails.root.join("spec", "fixtures", "files", "test_image.jpg") }

  before do
    unit.photo.attach(
      io: File.open(test_image_path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  describe ".full_size" do
    context "when image is attached" do
      it "returns a variant with 1200px max size without upscaling" do
        variant = described_class.full_size(unit.photo)

        expect(variant).to be_a(ActiveStorage::VariantWithRecord)
        expect(variant.variation.transformations).to include(
          resize_to_limit: [1200, 1200],
          format: :jpeg,
          saver: {quality: 75}
        )
      end

      it "uses the correct size constant" do
        variant = described_class.full_size(unit.photo)

        expect(variant.variation.transformations[:resize_to_limit]).to eq([ImageProcessorService::FULL_SIZE, ImageProcessorService::FULL_SIZE])
      end
    end

    context "when image is not attached" do
      before do
        unit.photo.purge
      end

      it "returns nil" do
        result = described_class.full_size(unit.photo)

        expect(result).to be_nil
      end
    end

    context "when attachment is nil" do
      it "returns nil" do
        result = described_class.full_size(nil)

        expect(result).to be_nil
      end
    end
  end

  describe ".thumbnail" do
    context "when image is attached" do
      it "returns a 200px thumbnail variant without upscaling" do
        variant = described_class.thumbnail(unit.photo)

        expect(variant).to be_a(ActiveStorage::VariantWithRecord)
        expect(variant.variation.transformations).to include(
          resize_to_limit: [200, 200],
          format: :jpeg,
          saver: {quality: 75}
        )
      end

      it "uses the correct size constant" do
        variant = described_class.thumbnail(unit.photo)

        expect(variant.variation.transformations[:resize_to_limit]).to eq([ImageProcessorService::THUMBNAIL_SIZE, ImageProcessorService::THUMBNAIL_SIZE])
      end
    end

    context "when image is not attached" do
      before do
        unit.photo.purge
      end

      it "returns nil" do
        result = described_class.thumbnail(unit.photo)

        expect(result).to be_nil
      end
    end
  end

  describe "constants" do
    it "has correct size constants" do
      expect(ImageProcessorService::FULL_SIZE).to eq(1200)
      expect(ImageProcessorService::THUMBNAIL_SIZE).to eq(200)
    end
  end
end