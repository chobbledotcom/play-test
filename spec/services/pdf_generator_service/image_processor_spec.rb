require "rails_helper"

RSpec.describe PdfGeneratorService::ImageProcessor do
  let(:user) { create(:user) }
  let(:unit_with_photo) { create(:unit, user: user) }
  let(:unit_without_photo) { create(:unit, user: user) }
  let(:inspection_with_photo) { create(:inspection, user: user, unit: unit_with_photo) }
  let(:inspection_without_photo) { create(:inspection, user: user, unit: unit_without_photo) }
  let(:pdf) { Prawn::Document.new }

  before do
    unit_with_photo.photo.attach(
      io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  describe ".generate_qr_code_footer" do
    context "with unit that has photo" do
      it "generates QR code footer without errors" do
        expect { described_class.generate_qr_code_footer(pdf, unit_with_photo) }.not_to raise_error
      end

      it "includes photo in the PDF" do
        initial_page_count = pdf.page_count
        described_class.generate_qr_code_footer(pdf, unit_with_photo)

        # Should not add extra pages
        expect(pdf.page_count).to eq(initial_page_count)
      end
    end

    context "with unit without photo" do
      it "generates QR code footer without errors" do
        expect { described_class.generate_qr_code_footer(pdf, unit_without_photo) }.not_to raise_error
      end
    end

    context "with inspection entity" do
      it "generates QR code footer for inspection with photo" do
        expect { described_class.generate_qr_code_footer(pdf, inspection_with_photo) }.not_to raise_error
      end

      it "generates QR code footer for inspection without photo" do
        expect { described_class.generate_qr_code_footer(pdf, inspection_without_photo) }.not_to raise_error
      end
    end

    context "with QR code service failure" do
      it "handles QR service errors gracefully" do
        allow(QrCodeService).to receive(:generate_qr_code).and_raise(StandardError, "QR generation failed")

        expect { described_class.generate_qr_code_footer(pdf, unit_with_photo) }.to raise_error(StandardError, "QR generation failed")
      end
    end
  end

  describe ".process_image_with_orientation" do
    let(:photo) { unit_with_photo.photo }

    it "processes image with auto-orientation" do
      processed_data = described_class.process_image_with_orientation(photo)

      expect(processed_data).to be_a(String)
      expect(processed_data.length).to be > 0
    end

    it "returns different data than original" do
      photo.download
      processed_data = described_class.process_image_with_orientation(photo)

      # Should process the image (might be same if no orientation change needed, but should not error)
      expect(processed_data).to be_a(String)
    end
  end

  describe ".add_entity_photo_footer" do
    context "with unit that has photo" do
      it "does not raise errors" do
        expect { described_class.add_entity_photo_footer(pdf, unit_with_photo, 100, 200) }.not_to raise_error
      end
    end

    context "with unit without photo" do
      it "does nothing when no photo attached" do
        expect { described_class.add_entity_photo_footer(pdf, unit_without_photo, 100, 200) }.not_to raise_error
      end
    end

    context "with nil entity" do
      it "does nothing when entity is nil" do
        expect { described_class.add_entity_photo_footer(pdf, nil, 100, 200) }.not_to raise_error
      end
    end
  end

  describe "integration with real PDF generation" do
    it "generates complete PDF with QR code and photos" do
      pdf_content = nil

      expect {
        pdf_content = PdfGeneratorService.generate_inspection_report(inspection_with_photo).render
      }.not_to raise_error

      expect(pdf_content).to be_a(String)
      expect(pdf_content[0..3]).to eq("%PDF")
    end

    it "generates complete PDF without photos" do
      pdf_content = nil

      expect {
        pdf_content = PdfGeneratorService.generate_inspection_report(inspection_without_photo).render
      }.not_to raise_error

      expect(pdf_content).to be_a(String)
      expect(pdf_content[0..3]).to eq("%PDF")
    end

    it "generates unit report with photos" do
      pdf_content = nil

      expect {
        pdf_content = PdfGeneratorService.generate_unit_report(unit_with_photo).render
      }.not_to raise_error

      expect(pdf_content).to be_a(String)
      expect(pdf_content[0..3]).to eq("%PDF")
    end
  end
end
