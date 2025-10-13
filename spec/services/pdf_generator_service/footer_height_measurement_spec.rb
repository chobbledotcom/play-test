# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::DisclaimerFooterRenderer do
  let(:user) { create(:user) }
  let(:pdf) { Prawn::Document.new }

  describe "#measure_footer_height" do
    context "when branded" do
      it "returns footer height" do
        height = described_class.measure_footer_height(unbranded: false)
        expect(height).to eq(
          PdfGeneratorService::Configuration::FOOTER_HEIGHT
        )
      end
    end

    context "when unbranded" do
      it "returns 0" do
        height = described_class.measure_footer_height(unbranded: true)
        expect(height).to eq(0)
      end
    end
  end
end
