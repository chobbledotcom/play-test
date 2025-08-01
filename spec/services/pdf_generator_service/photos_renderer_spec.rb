require "rails_helper"

RSpec.describe PdfGeneratorService::PhotosRenderer do
  let(:pdf) { instance_double(Prawn::Document) }
  let(:inspection) { instance_double("Inspection") }
  let(:photo_attachment) { instance_double("ActiveStorage::Attached::One") }
  let(:photo_blob) { instance_double("ActiveStorage::Blob") }
  # photo is removed - we should use photo_attachment which is ActiveStorage::Attached::One

  # Mock configuration constants
  before do
    stub_const("PdfGeneratorService::Configuration::HEADER_TEXT_SIZE", 16)
    stub_const("PdfGeneratorService::Configuration::PHOTO_MAX_HEIGHT_PERCENT", 0.4)
    stub_const("PdfGeneratorService::Configuration::PHOTO_SPACING", 10)
    stub_const("PdfGeneratorService::Configuration::PHOTO_LABEL_SIZE", 12)
    stub_const("PdfGeneratorService::Configuration::PHOTO_LABEL_SPACING", 5)
  end

  describe ".generate_photos_page" do
    context "when inspection has no photos" do
      before do
        allow(described_class).to receive(:has_photos?).with(inspection).and_return(false)
      end

      it "returns early without creating a photos page" do
        expect(pdf).not_to receive(:start_new_page)
        described_class.generate_photos_page(pdf, inspection)
      end
    end

    context "when inspection has photos" do
      before do
        allow(described_class).to receive(:has_photos?).with(inspection).and_return(true)
        allow(pdf).to receive(:start_new_page)
        allow(described_class).to receive(:add_photos_header)
        allow(described_class).to receive(:calculate_max_photo_height).and_return(300)
        allow(described_class).to receive(:process_all_photos)
      end

      it "creates a new page and processes photos" do
        expect(pdf).to receive(:start_new_page)
        expect(described_class).to receive(:add_photos_header).with(pdf)
        expect(described_class).to receive(:calculate_max_photo_height).with(pdf)
        expect(described_class).to receive(:process_all_photos).with(pdf, inspection, 300)

        described_class.generate_photos_page(pdf, inspection)
      end
    end
  end

  describe ".has_photos?" do
    before do
      allow(inspection).to receive(:photo_1).and_return(photo_attachment)
      allow(inspection).to receive(:photo_2).and_return(photo_attachment)
      allow(inspection).to receive(:photo_3).and_return(photo_attachment)
    end

    context "when no photos are attached" do
      before do
        allow(photo_attachment).to receive(:attached?).and_return(false)
      end

      it "returns false" do
        expect(described_class.has_photos?(inspection)).to be false
      end
    end

    context "when photo_1 is attached" do
      before do
        allow(photo_attachment).to receive(:attached?).and_return(false)
        allow(inspection).to receive(:photo_1).and_return(photo_attachment)
        allow(inspection).to receive_message_chain(:photo_1, :attached?).and_return(true)
      end

      it "returns true" do
        expect(described_class.has_photos?(inspection)).to be true
      end
    end

    context "when photo_2 is attached" do
      before do
        allow(photo_attachment).to receive(:attached?).and_return(false)
        allow(inspection).to receive(:photo_2).and_return(photo_attachment)
        allow(inspection).to receive_message_chain(:photo_2, :attached?).and_return(true)
      end

      it "returns true" do
        expect(described_class.has_photos?(inspection)).to be true
      end
    end

    context "when photo_3 is attached" do
      before do
        allow(photo_attachment).to receive(:attached?).and_return(false)
        allow(inspection).to receive(:photo_3).and_return(photo_attachment)
        allow(inspection).to receive_message_chain(:photo_3, :attached?).and_return(true)
      end

      it "returns true" do
        expect(described_class.has_photos?(inspection)).to be true
      end
    end
  end

  describe ".add_photos_header" do
    before do
      allow(pdf).to receive(:text)
      allow(pdf).to receive(:stroke_horizontal_rule)
      allow(pdf).to receive(:move_down)
    end

    it "adds header text with correct formatting" do
      expect(pdf).to receive(:text).with(
        I18n.t("pdf.inspection.photos_section"),
        {size: 16, style: :bold}
      )
      described_class.add_photos_header(pdf)
    end

    it "adds horizontal rule and spacing" do
      expect(pdf).to receive(:stroke_horizontal_rule)
      expect(pdf).to receive(:move_down).with(15)
      described_class.add_photos_header(pdf)
    end
  end

  describe ".calculate_max_photo_height" do
    let(:bounds) { instance_double("Bounds", height: 792) }

    before do
      allow(pdf).to receive(:bounds).and_return(bounds)
    end

    it "calculates 40% of page height" do
      result = described_class.calculate_max_photo_height(pdf)
      expect(result).to eq(316.8)
    end
  end

  describe ".process_all_photos" do
    let(:cursor_position) { 700 }

    before do
      allow(pdf).to receive(:cursor).and_return(cursor_position)
      allow(pdf).to receive(:move_down)
      allow(inspection).to receive(:photo_1).and_return(photo_attachment)
      allow(inspection).to receive(:photo_2).and_return(photo_attachment)
      allow(inspection).to receive(:photo_3).and_return(photo_attachment)
    end

    context "when no photos are attached" do
      before do
        allow(photo_attachment).to receive(:attached?).and_return(false)
      end

      it "does not render any photos" do
        expect(described_class).not_to receive(:render_photo)
        described_class.process_all_photos(pdf, inspection, 300)
      end
    end

    context "when photos are attached" do
      before do
        allow(inspection).to receive(:send).with(:photo_1).and_return(photo_attachment)
        allow(inspection).to receive(:send).with(:photo_2).and_return(photo_attachment)
        allow(inspection).to receive(:send).with(:photo_3).and_return(photo_attachment)
        allow(photo_attachment).to receive(:attached?).and_return(true)
        allow(photo_attachment).to receive(:blob).and_return(photo_blob)
        allow(described_class).to receive(:handle_page_break_if_needed).and_return(cursor_position)
        allow(described_class).to receive(:render_photo)
      end

      it "renders each attached photo" do
        expect(described_class).to receive(:render_photo).exactly(3).times
        described_class.process_all_photos(pdf, inspection, 300)
      end

      it "handles page breaks and spacing" do
        expect(described_class).to receive(:handle_page_break_if_needed).exactly(3).times
        expect(pdf).to receive(:move_down).with(10).exactly(3).times
        described_class.process_all_photos(pdf, inspection, 300)
      end
    end

    context "when only some photos are attached" do
      let(:photo_1_attached) { instance_double("ActiveStorage::Attached::One") }
      let(:photo_1) { instance_double("ActiveStorage::Attachment", blob: photo_blob) }
      let(:photo_2_attached) { instance_double("ActiveStorage::Attached::One") }
      let(:photo_3_attached) { instance_double("ActiveStorage::Attached::One") }
      let(:photo_3) { instance_double("ActiveStorage::Attachment", blob: photo_blob) }

      before do
        allow(inspection).to receive(:send).with(:photo_1).and_return(photo_1_attached)
        allow(inspection).to receive(:send).with(:photo_2).and_return(photo_2_attached)
        allow(inspection).to receive(:send).with(:photo_3).and_return(photo_3_attached)
        allow(photo_1_attached).to receive(:blob).and_return(photo_blob)
        allow(photo_3_attached).to receive(:blob).and_return(photo_blob)
        allow(described_class).to receive(:handle_page_break_if_needed).and_return(cursor_position)
        allow(described_class).to receive(:render_photo)
      end

      it "only renders attached photos" do
        expect(described_class).to receive(:render_photo).twice
        described_class.process_all_photos(pdf, inspection, 300)
      end

      it "updates cursor position correctly" do
        allow(pdf).to receive(:cursor).and_return(700, 650, 600)
        expect(pdf).to receive(:move_down).with(10).twice
        described_class.process_all_photos(pdf, inspection, 300)
      end
    end

    context "when cursor position changes during rendering" do
      before do
        allow(inspection).to receive(:send).with(:photo_1).and_return(photo_attachment)
        allow(inspection).to receive(:send).with(:photo_2).and_return(photo_attachment)
        allow(inspection).to receive(:send).with(:photo_3).and_return(photo_attachment)
        allow(photo_attachment).to receive(:attached?).and_return(true)
        allow(photo_attachment).to receive(:blob).and_return(photo_blob)
        allow(described_class).to receive(:render_photo)
        allow(pdf).to receive(:cursor).and_return(700, 650, 600, 550, 500, 450)
      end

      it "tracks cursor position correctly" do
        expect(described_class).to receive(:handle_page_break_if_needed)
          .with(pdf, 700, 300).ordered.and_return(700)
        expect(described_class).to receive(:handle_page_break_if_needed)
          .with(pdf, 640, 300).ordered.and_return(640)
        expect(described_class).to receive(:handle_page_break_if_needed)
          .with(pdf, 540, 300).ordered.and_return(540)

        described_class.process_all_photos(pdf, inspection, 300)
      end
    end
  end

  describe ".photo_fields" do
    it "returns array of photo field symbols and labels" do
      fields = described_class.photo_fields
      expect(fields).to be_an(Array)
      expect(fields.size).to eq(3)
      expect(fields[0][0]).to eq(:photo_1)
      expect(fields[1][0]).to eq(:photo_2)
      expect(fields[2][0]).to eq(:photo_3)
    end

    it "includes I18n labels for each photo" do
      fields = described_class.photo_fields
      expect(fields[0][1]).to eq(I18n.t("pdf.inspection.fields.photo_1_label"))
      expect(fields[1][1]).to eq(I18n.t("pdf.inspection.fields.photo_2_label"))
      expect(fields[2][1]).to eq(I18n.t("pdf.inspection.fields.photo_3_label"))
    end

    it "returns the same array structure each time" do
      fields1 = described_class.photo_fields
      fields2 = described_class.photo_fields
      expect(fields1).to eq(fields2)
    end
  end

  describe ".handle_page_break_if_needed" do
    context "when there is enough space" do
      it "returns the current cursor position" do
        result = described_class.handle_page_break_if_needed(pdf, 500, 300)
        expect(result).to eq(500)
      end
    end

    context "when there is not enough space" do
      before do
        allow(pdf).to receive(:start_new_page)
        allow(pdf).to receive(:cursor).and_return(700)
      end

      it "starts a new page and returns new cursor position" do
        expect(pdf).to receive(:start_new_page)
        result = described_class.handle_page_break_if_needed(pdf, 200, 300)
        expect(result).to eq(700)
      end
    end
  end

  describe ".calculate_needed_space" do
    it "calculates total space needed for photo and labels" do
      # max_photo_height + label_size + label_spacing + photo_spacing
      # 300 + 12 + 5 + 10 = 327
      result = described_class.calculate_needed_space(300)
      expect(result).to eq(327)
    end
  end

  describe ".render_photo" do
    let(:image_data) { "fake_image_data" }
    let(:bounds) { instance_double("Bounds", width: 500) }

    before do
      allow(photo_attached_one).to receive(:blob).and_return(photo_blob)
      allow(photo_blob).to receive(:download)
      allow(photo_blob).to receive(:metadata).and_return({width: 800, height: 600})
      allow(PdfGeneratorService::ImageProcessor).to receive(:process_image_with_orientation).and_return(image_data)
      allow(pdf).to receive(:bounds).and_return(bounds)
      allow(pdf).to receive(:cursor).and_return(700)
      allow(pdf).to receive(:image)
      allow(described_class).to receive(:add_photo_label)
    end

    it "downloads and processes the image" do
      expect(photo_blob).to receive(:download)
      expect(PdfGeneratorService::ImageProcessor).to receive(:process_image_with_orientation).with(photo_attached_one)
      described_class.render_photo(pdf, photo_attached_one, "Test Label", 300)
    end

    it "calculates dimensions and renders image" do
      expect(described_class).to receive(:calculate_photo_dimensions_from_blob).and_return([400, 300])
      expect(pdf).to receive(:image).with(
        instance_of(StringIO),
        {at: [50, 700], width: 400, height: 300}
      )
      described_class.render_photo(pdf, photo_attached_one, "Test Label", 300)
    end

    it "adds photo label" do
      expect(described_class).to receive(:add_photo_label).with(pdf, "Test Label", 300)
      described_class.render_photo(pdf, photo_attached_one, "Test Label", 300)
    end

    it "centers image horizontally" do
      allow(described_class).to receive(:calculate_photo_dimensions_from_blob).and_return([200, 150])
      expect(pdf).to receive(:image).with(
        instance_of(StringIO),
        {at: [150, 700], width: 200, height: 150}  # (500 - 200) / 2 = 150
      )
      described_class.render_photo(pdf, photo_attached_one, "Test Label", 300)
    end

    context "with different image dimensions" do
      it "handles wide images" do
        allow(described_class).to receive(:calculate_photo_dimensions_from_blob).and_return([500, 200])
        expect(pdf).to receive(:image).with(
          instance_of(StringIO),
          {at: [0, 700], width: 500, height: 200}  # (500 - 500) / 2 = 0
        )
        described_class.render_photo(pdf, photo_attached_one, "Test Label", 300)
      end

      it "handles narrow images" do
        allow(described_class).to receive(:calculate_photo_dimensions_from_blob).and_return([100, 300])
        expect(pdf).to receive(:image).with(
          instance_of(StringIO),
          {at: [200, 700], width: 100, height: 300}  # (500 - 100) / 2 = 200
        )
        described_class.render_photo(pdf, photo_attached_one, "Test Label", 300)
      end
    end

    context "when image type is unsupported" do
      before do
        allow(PdfGeneratorService::ImageProcessor).to receive(:process_image_with_orientation)
          .and_raise(Prawn::Errors::UnsupportedImageType.new("Unsupported"))
      end

      it "raises ImageError with details" do
        expect(PdfGeneratorService::ImageError).to receive(:build_detailed_error)
        expect { described_class.render_photo(pdf, photo_attached_one, "Test Label", 300) }.to raise_error
      end
    end

    context "when render_image_to_pdf raises error" do
      before do
        allow(described_class).to receive(:render_image_to_pdf)
          .and_raise(Prawn::Errors::UnsupportedImageType.new("Error in render"))
      end

      it "does not call add_photo_label" do
        expect(described_class).not_to receive(:add_photo_label)
        expect { described_class.render_photo(pdf, photo_attached_one, "Test Label", 300) }.to raise_error
      end
    end
  end

  describe ".calculate_photo_dimensions_from_blob" do
    let(:metadata) { {width: 800, height: 600} }
    let(:photo_attached_one) { instance_double("ActiveStorage::Attached::One") }

    before do
      allow(photo_attached_one).to receive(:blob).and_return(photo_blob)
      allow(photo_blob).to receive(:metadata).and_return(metadata)
    end

    context "when width is limiting factor" do
      it "scales based on width" do
        width, height = described_class.calculate_photo_dimensions_from_blob(photo_attached_one, 400, 600)
        expect(width).to eq(400)
        expect(height).to eq(300)
      end
    end

    context "when height is limiting factor" do
      it "scales based on height" do
        width, height = described_class.calculate_photo_dimensions_from_blob(photo_attached_one, 1000, 300)
        expect(width).to eq(400)
        expect(height).to eq(300)
      end
    end

    context "with square image" do
      let(:metadata) { {width: 500, height: 500} }

      it "scales proportionally" do
        width, height = described_class.calculate_photo_dimensions_from_blob(photo_attached_one, 300, 400)
        expect(width).to eq(300)
        expect(height).to eq(300)
      end
    end

    context "with portrait image" do
      let(:metadata) { {width: 400, height: 800} }

      it "scales based on height when limited by max height" do
        width, height = described_class.calculate_photo_dimensions_from_blob(photo_attached_one, 500, 400)
        expect(width).to eq(200)
        expect(height).to eq(400)
      end
    end

    context "with very small image" do
      let(:metadata) { {width: 100, height: 100} }

      it "does not upscale beyond original size" do
        width, height = described_class.calculate_photo_dimensions_from_blob(photo_attached_one, 500, 500)
        expect(width).to eq(100)
        expect(height).to eq(100)
      end
    end

    context "with zero dimensions" do
      let(:metadata) { {width: 0, height: 600} }

      it "handles zero width gracefully" do
        expect {
          described_class.calculate_photo_dimensions_from_blob(photo_attached_one, 400, 300)
        }.to raise_error(ZeroDivisionError)
      end
    end

    context "with nil metadata values" do
      let(:metadata) { {width: nil, height: 600} }

      it "converts nil to zero and handles error" do
        expect {
          described_class.calculate_photo_dimensions_from_blob(photo_attached_one, 400, 300)
        }.to raise_error(ZeroDivisionError)
      end
    end
  end

  describe ".render_image_to_pdf" do
    let(:image_data) { "fake_image_data" }
    let(:photo_attached_one) { instance_double("ActiveStorage::Attached::One") }

    before do
      allow(photo_attached_one).to receive(:blob).and_return(photo_blob)
      allow(pdf).to receive(:cursor).and_return(700)
      allow(pdf).to receive(:image)
    end

    it "renders image with correct options" do
      expect(pdf).to receive(:image).with(
        instance_of(StringIO),
        {at: [100, 700], width: 400, height: 300}
      )
      described_class.render_image_to_pdf(pdf, image_data, 100, 400, 300, photo_attached_one)
    end

    context "when Prawn raises unsupported image error" do
      before do
        allow(pdf).to receive(:image).and_raise(Prawn::Errors::UnsupportedImageType.new("Unsupported"))
      end

      it "raises ImageError with details" do
        expect(PdfGeneratorService::ImageError).to receive(:build_detailed_error)
          .with(instance_of(Prawn::Errors::UnsupportedImageType), photo_attached_one)
        expect {
          described_class.render_image_to_pdf(pdf, image_data, 100, 400, 300, photo_attached_one)
        }.to raise_error
      end
    end
  end

  describe ".add_photo_label" do
    before do
      allow(pdf).to receive(:move_down)
      allow(pdf).to receive(:text)
    end

    it "positions label below image" do
      expect(pdf).to receive(:move_down).with(305)
      described_class.add_photo_label(pdf, "Test Label", 300)
    end

    it "renders centered label text" do
      expect(pdf).to receive(:text).with(
        "Test Label",
        {size: 12, align: :center}
      )
      described_class.add_photo_label(pdf, "Test Label", 300)
    end
  end

  describe "integration scenarios" do
    let(:bounds) { instance_double("Bounds", width: 500, height: 792) }

    before do
      allow(pdf).to receive(:bounds).and_return(bounds)
      allow(pdf).to receive(:start_new_page)
      allow(pdf).to receive(:text)
      allow(pdf).to receive(:stroke_horizontal_rule)
      allow(pdf).to receive(:move_down)
      allow(pdf).to receive(:cursor).and_return(700)
      allow(pdf).to receive(:image)
    end

    context "complete photo rendering flow" do
      let(:photo_1_attached) { instance_double("ActiveStorage::Attached::One") }
      let(:photo_2_attached) { instance_double("ActiveStorage::Attached::One") }
      let(:photo_3_attached) { instance_double("ActiveStorage::Attached::One") }

      before do
        allow(inspection).to receive(:photo_1).and_return(photo_1_attached)
        allow(inspection).to receive(:photo_2).and_return(photo_2_attached)
        allow(inspection).to receive(:photo_3).and_return(photo_3_attached)
        allow(inspection).to receive(:send).with(:photo_1).and_return(photo_1_attached)
        allow(inspection).to receive(:send).with(:photo_2).and_return(photo_2_attached)
        allow(inspection).to receive(:send).with(:photo_3).and_return(photo_3_attached)
        allow(photo_1_attached).to receive(:attached?).and_return(true)
        allow(photo_2_attached).to receive(:attached?).and_return(false)
        allow(photo_3_attached).to receive(:attached?).and_return(true)
        allow(photo_1_attached).to receive(:blob).and_return(photo_blob)
        allow(photo_3_attached).to receive(:blob).and_return(photo_blob)
        allow(photo_blob).to receive(:download)
        allow(photo_blob).to receive(:metadata).and_return({width: 800, height: 600})
        allow(PdfGeneratorService::ImageProcessor).to receive(:process_image_with_orientation).and_return("image_data")
      end

      it "renders a complete photos page with multiple photos" do
        expect(pdf).to receive(:start_new_page).once
        expect(pdf).to receive(:text).with(I18n.t("pdf.inspection.photos_section"), anything).once
        expect(pdf).to receive(:stroke_horizontal_rule).once
        expect(pdf).to receive(:move_down).with(15).once
        expect(pdf).to receive(:image).twice  # Only photo_1 and photo_3
        expect(pdf).to receive(:text).with(I18n.t("pdf.inspection.fields.photo_1_label"), anything).once
        expect(pdf).to receive(:text).with(I18n.t("pdf.inspection.fields.photo_3_label"), anything).once

        described_class.generate_photos_page(pdf, inspection)
      end
    end

    context "page break scenarios" do
      let(:photo_1_attached) { instance_double("ActiveStorage::Attached::One") }

      before do
        allow(inspection).to receive(:photo_1).and_return(photo_1_attached)
        allow(inspection).to receive(:photo_2).and_return(photo_attachment)
        allow(inspection).to receive(:photo_3).and_return(photo_attachment)
        allow(photo_attachment).to receive(:attached?).and_return(false)
        allow(inspection).to receive(:send).with(:photo_1).and_return(photo_1_attached)
        allow(photo_1_attached).to receive(:attached?).and_return(true)
        allow(photo_1_attached).to receive(:blob).and_return(photo_blob)
        allow(photo_blob).to receive(:download)
        allow(photo_blob).to receive(:metadata).and_return({width: 800, height: 600})
        allow(PdfGeneratorService::ImageProcessor).to receive(:process_image_with_orientation).and_return("image_data")
      end

      it "handles page breaks correctly when space is limited" do
        # Simulate low cursor position that triggers page break
        allow(pdf).to receive(:cursor).and_return(100, 792, 792)

        expect(pdf).to receive(:start_new_page).twice  # Once for photos page, once for page break

        described_class.generate_photos_page(pdf, inspection)
      end
    end

    context "error recovery" do
      let(:good_photo_attached) { instance_double("ActiveStorage::Attached::One") }
      let(:bad_blob) { instance_double("ActiveStorage::Blob") }
      let(:bad_photo_attached) { instance_double("ActiveStorage::Attached::One") }

      before do
        allow(inspection).to receive(:photo_1).and_return(good_photo_attached)
        allow(inspection).to receive(:photo_2).and_return(bad_photo_attached)
        allow(inspection).to receive(:photo_3).and_return(photo_attachment)
        allow(photo_attachment).to receive(:attached?).and_return(false)
        allow(inspection).to receive(:send).with(:photo_1).and_return(good_photo_attached)
        allow(good_photo_attached).to receive(:attached?).and_return(true)
        allow(good_photo_attached).to receive(:blob).and_return(photo_blob)
        allow(bad_photo_attached).to receive(:attached?).and_return(true)
        allow(bad_photo_attached).to receive(:blob).and_return(bad_blob)
        allow(inspection).to receive(:send).with(:photo_2).and_return(bad_photo_attached)

        allow(photo_blob).to receive(:download)
        allow(photo_blob).to receive(:metadata).and_return({width: 800, height: 600})
        allow(PdfGeneratorService::ImageProcessor).to receive(:process_image_with_orientation).with(good_photo_attached).and_return("good_data")

        allow(bad_blob).to receive(:download)
        allow(bad_blob).to receive(:metadata).and_return({width: 800, height: 600})
        allow(PdfGeneratorService::ImageProcessor).to receive(:process_image_with_orientation)
          .with(bad_photo_attached).and_raise(Prawn::Errors::UnsupportedImageType.new("Bad format"))
      end

      it "stops processing after first error" do
        expect(pdf).to receive(:image).once  # Only the first photo
        expect(PdfGeneratorService::ImageError).to receive(:build_detailed_error)

        expect { described_class.generate_photos_page(pdf, inspection) }.to raise_error
      end
    end
  end
end
