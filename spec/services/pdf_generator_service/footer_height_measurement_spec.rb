# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::DisclaimerFooterRenderer do
  let(:user) { create(:user) }
  let(:pdf) { Prawn::Document.new }

  describe "#measure_footer_height" do
    context "when on first page" do
      it "returns footer height when disclaimer should be rendered" do
        height = described_class.measure_footer_height(pdf)
        expect(height).not_to be 0
      end
    end

    context "when not on first page" do
      it "returns 0 when disclaimer should not be rendered" do
        pdf.start_new_page
        height = described_class.measure_footer_height(pdf)
        expect(height).to eq(0)
      end
    end
  end
end
