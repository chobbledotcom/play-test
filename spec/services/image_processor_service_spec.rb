require "rails_helper"

RSpec.describe ImageProcessorService do
  let(:unit) { create(:unit) }
  let(:test_image_path) do
    Rails.root.join("spec/fixtures/files/test_image.jpg")
  end

  before do
    unit.photo.attach(
      io: File.open(test_image_path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  describe ".calculate_dimensions" do
    let(:metadata) { {"width" => 2000, "height" => 1500} }

    context "when calculating full size dimensions" do
      it "returns dimensions limited to FULL_SIZE constant" do
        dimensions = described_class.calculate_dimensions(metadata, :full)

        expect(dimensions[:width]).to eq(1200)
        expect(dimensions[:height]).to eq(900)
      end
    end

    context "when calculating thumbnail dimensions" do
      it "returns dimensions limited to THUMBNAIL_SIZE constant" do
        dimensions = described_class.calculate_dimensions(metadata, :thumbnail)

        expect(dimensions[:width]).to eq(200)
        expect(dimensions[:height]).to eq(150)
      end
    end

    context "when calculating default dimensions" do
      it "returns dimensions limited to DEFAULT_SIZE constant" do
        dimensions = described_class.calculate_dimensions(metadata, :default)

        expect(dimensions[:width]).to eq(800)
        expect(dimensions[:height]).to eq(600)
      end
    end

    context "when image is smaller than limit" do
      let(:metadata) { {"width" => 100, "height" => 75} }

      it "returns original dimensions without upscaling" do
        dimensions = described_class.calculate_dimensions(metadata, :thumbnail)

        expect(dimensions[:width]).to eq(100)
        expect(dimensions[:height]).to eq(75)
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
        expected_size = [
          ImageProcessorService::THUMBNAIL_SIZE,
          ImageProcessorService::THUMBNAIL_SIZE
        ]

        expect(variant.variation.transformations[:resize_to_limit])
          .to eq(expected_size)
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
      it "returns a 800px default variant without upscaling" do
        variant = described_class.default(unit.photo)

        expect(variant).to be_a(ActiveStorage::VariantWithRecord)
        expect(variant.variation.transformations).to include(
          resize_to_limit: [800, 800],
          format: :jpeg,
          saver: {quality: 75}
        )
      end

      it "uses the correct size constant" do
        variant = described_class.default(unit.photo)
        expected_size = [
          ImageProcessorService::DEFAULT_SIZE,
          ImageProcessorService::DEFAULT_SIZE
        ]

        expect(variant.variation.transformations[:resize_to_limit])
          .to eq(expected_size)
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
      expect(ImageProcessorService::DEFAULT_SIZE).to eq(800)
    end
  end
end
