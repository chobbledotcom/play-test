# typed: false

require "rails_helper"

RSpec.describe PdfGeneratorService::HeaderGenerator do
  let(:user) { create(:user) }
  let(:pdf) { Prawn::Document.new }
  let(:logo_height) { PdfGeneratorService::Configuration::LOGO_HEIGHT }
  let(:expected_logo_width) { logo_height * 2 + 10 }

  describe ".prepare_logo" do
    context "when PDF_LOGO configuration is set" do
      let(:logo_filename) { "test_logo.png" }
      let(:logo_path) { Rails.root.join("app", "assets", "images", logo_filename) }
      let(:logo_data) { "fake logo data" }

      before do
        Rails.configuration.pdf_logo = logo_filename
        allow(File).to receive(:read).with(logo_path, mode: "rb").and_return(logo_data)
      end

      after do
        Rails.configuration.pdf_logo = nil
      end

      it "returns logo data from the specified file" do
        logo_width, data, attachment = described_class.send(:prepare_logo, user)

        expect(logo_width).to eq(expected_logo_width)
        expect(data).to eq(logo_data)
        expect(attachment).to be_nil
      end

      it "ignores user logo even if attached" do
        user.logo.attach(fixture_file_upload("test_image.jpg", "image/jpeg"))

        logo_width, data, attachment = described_class.send(:prepare_logo, user)

        expect(logo_width).to eq(expected_logo_width)
        expect(data).to eq(logo_data)
        expect(attachment).to be_nil
      end

      context "when the file does not exist" do
        it "raises an error" do
          allow(File).to receive(:read).with(logo_path, mode: "rb").and_raise(Errno::ENOENT)

          expect {
            described_class.send(:prepare_logo, user)
          }.to raise_error(Errno::ENOENT)
        end
      end
    end

    context "when PDF_LOGO configuration is not set" do
      before do
        Rails.configuration.pdf_logo = nil
      end

      context "when user is nil" do
        it "returns empty values" do
          logo_width, data, attachment = described_class.send(:prepare_logo, nil)

          expect(logo_width).to eq(0)
          expect(data).to be_nil
          expect(attachment).to be_nil
        end
      end

      context "when user has no logo attached" do
        it "returns empty values" do
          logo_width, data, attachment = described_class.send(:prepare_logo, user)

          expect(logo_width).to eq(0)
          expect(data).to be_nil
          expect(attachment).to be_nil
        end
      end

      context "when user has logo attached" do
        let(:logo_content) { Rails.root.join("spec/fixtures/files/test_image.jpg").read(mode: "rb") }

        before do
          user.logo.attach(fixture_file_upload("test_image.jpg", "image/jpeg"))
          user.logo.blob.analyze
        end

        it "returns logo data from user's attached logo" do
          logo_width, data, attachment = described_class.send(:prepare_logo, user)

          expect(logo_width).to eq(expected_logo_width)
          expect(data).to eq(logo_content)
          expect(attachment).to eq(user.logo)
        end

        it "downloads the logo data" do
          expect(user.logo).to receive(:download).and_return(logo_content)

          described_class.send(:prepare_logo, user)
        end
      end

      context "when user logo attachment is broken" do
        before do
          user.logo.attach(fixture_file_upload("test_image.jpg", "image/jpeg"))
          allow(user.logo).to receive(:download).and_raise(ActiveStorage::FileNotFoundError)
        end

        it "raises the error" do
          expect {
            described_class.send(:prepare_logo, user)
          }.to raise_error(ActiveStorage::FileNotFoundError)
        end
      end
    end

    context "with empty PDF_LOGO value" do
      before do
        Rails.configuration.pdf_logo = ""
      end

      after do
        Rails.configuration.pdf_logo = nil
      end

      it "treats empty string as not set" do
        logo_width, data, attachment = described_class.send(:prepare_logo, user)

        expect(logo_width).to eq(0)
        expect(data).to be_nil
        expect(attachment).to be_nil
      end
    end

    context "logo dimensions calculation" do
      context "when returning logo data" do
        before do
          user.logo.attach(fixture_file_upload("test_image.jpg", "image/jpeg"))
        end

        it "calculates consistent width based on height" do
          logo_width, _, _ = described_class.send(:prepare_logo, user)

          expect(logo_width).to eq(logo_height * 2 + 10)
        end

        it "uses the configured LOGO_HEIGHT constant" do
          expect(PdfGeneratorService::Configuration::LOGO_HEIGHT).to be > 0

          logo_width, _, _ = described_class.send(:prepare_logo, user)

          expect(logo_width).to eq(PdfGeneratorService::Configuration::LOGO_HEIGHT * 2 + 10)
        end
      end
    end
  end
end
