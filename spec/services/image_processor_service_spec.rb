require "rails_helper"

RSpec.describe ImageProcessorService do
  let(:unit) { create(:unit) }
  let(:test_image_path) { Rails.root.join("spec/fixtures/files/test_image.jpg") }

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
        expected_size = [ImageProcessorService::FULL_SIZE, ImageProcessorService::FULL_SIZE]

        expect(variant.variation.transformations[:resize_to_limit]).to eq(expected_size)
      end
    end

    context "when image is not attached" do
      before { unit.photo.purge }

      it "returns nil" do
        expect(described_class.full_size(unit.photo)).to be_nil
      end
    end

    context "when attachment is nil" do
      it "returns nil" do
        expect(described_class.full_size(nil)).to be_nil
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
        expected_size = [ImageProcessorService::THUMBNAIL_SIZE, ImageProcessorService::THUMBNAIL_SIZE]

        expect(variant.variation.transformations[:resize_to_limit]).to eq(expected_size)
      end
    end

    context "when image is not attached" do
      before { unit.photo.purge }

      it "returns nil" do
        expect(described_class.thumbnail(unit.photo)).to be_nil
      end
    end
  end

  describe ".default" do
    context "when image is attached" do
      it "returns a 600px default variant without upscaling" do
        variant = described_class.default(unit.photo)

        expect(variant).to be_a(ActiveStorage::VariantWithRecord)
        expect(variant.variation.transformations).to include(
          resize_to_limit: [600, 600],
          format: :jpeg,
          saver: {quality: 75}
        )
      end

      it "uses the correct size constant" do
        variant = described_class.default(unit.photo)
        expected_size = [ImageProcessorService::DEFAULT_SIZE, ImageProcessorService::DEFAULT_SIZE]

        expect(variant.variation.transformations[:resize_to_limit]).to eq(expected_size)
      end
    end

    context "when image is not attached" do
      before { unit.photo.purge }

      it "returns nil" do
        expect(described_class.default(unit.photo)).to be_nil
      end
    end
  end

  describe "constants" do
    it "has correct size constants" do
      expect(ImageProcessorService::FULL_SIZE).to eq(1200)
      expect(ImageProcessorService::THUMBNAIL_SIZE).to eq(200)
      expect(ImageProcessorService::DEFAULT_SIZE).to eq(600)
    end
  end
end
