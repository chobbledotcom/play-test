# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe QrCodeService do
  let(:inspection) { create(:inspection) }
  let(:unit) { create(:unit) }
  let(:base_url) { "https://example.com" }

  before do
    Rails.configuration.base_url = base_url
  end

  after do
    Rails.configuration.base_url = "http://localhost:3000"
  end

  shared_examples "generates QR code" do |record_type|
    let(:record) { send(record_type) }
    let(:method_name) { :"generate_#{record_type}_qr_code" }
    let(:expected_url) { "#{base_url}/#{record_type}s/#{record.id}" }

    it "delegates to correct method and returns QR code blob" do
      expect(described_class).to receive(method_name)
        .with(record).and_call_original
      expect(described_class).to receive(:generate_qr_code_from_url)
        .with(expected_url).and_call_original

      result = described_class.generate_qr_code(record)

      expect(result).to be_a(String)
      expect(result).not_to be_empty
      expect(result[0..3]).to eq("\x89PNG".b)
    end
  end

  describe ".generate_qr_code" do
    include_examples "generates QR code", :inspection
    include_examples "generates QR code", :unit

    # Note: We cannot test unsupported record types due to Sorbet's strict
    # typing. The method signature enforces T.any(Inspection, Unit) at
    # runtime, preventing us from passing any other type.
  end

  describe ".generate_qr_code_from_url" do
    it "generates unique PNG blobs for different URLs" do
      url1 = "https://example.com/1"
      url2 = "https://example.com/2"
      result1 = described_class.generate_qr_code_from_url(url1)
      result2 = described_class.generate_qr_code_from_url(url2)

      expect(result1).not_to eq(result2)
      [result1, result2].each do |result|
        expect(result[0..3]).to eq("\x89PNG".b)
      end
    end
  end

  describe "configuration methods" do
    it "returns expected QR code options" do
      expect(described_class.qr_code_options).to eq({level: :m})
    end

    it "returns expected PNG options" do
      expect(described_class.png_options).to include(
        bit_depth: 1,
        border_modules: 0,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: "black",
        file: nil,
        fill: "white",
        module_px_size: 8,
        resize_exactly_to: false,
        resize_gte_to: false,
        size: 300
      )
    end
  end

  context "when BASE_URL is not set" do
    before { Rails.configuration.base_url = nil }
    after { Rails.configuration.base_url = "http://localhost:3000" }

    %i[inspection unit].each do |record_type|
      it "raises TypeError for #{record_type} QR generation" do
        record = send(record_type)
        method = "generate_#{record_type}_qr_code"
        expect { described_class.send(method, record) }
          .to raise_error(TypeError)
      end
    end
  end
end
