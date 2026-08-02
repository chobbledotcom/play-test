# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfPerformance do
  describe ".measure" do
    it "returns the measured block result and logs its duration" do
      allow(Process).to receive(:clock_gettime).and_return(10.0, 10.125)
      allow(Rails.logger).to receive(:info)

      result = described_class.measure(
        :document_build,
        pdf_type: :inspection,
        record_id: "inspection-id",
        cached: false
      ) { :result }

      expect(result).to eq(:result)
      expect(Rails.logger).to have_received(:info).with({
        event: "pdf.performance",
        stage: :document_build,
        pdf_type: :inspection,
        record_id: "inspection-id",
        duration_ms: 125.0,
        cached: false
      })
    end

    it "logs timing and reraises errors from the measured block" do
      allow(Process).to receive(:clock_gettime).and_return(20.0, 20.01)
      allow(Rails.logger).to receive(:info)

      expect {
        described_class.measure(
          :document_render,
          pdf_type: :unit,
          record_id: "unit-id"
        ) { raise "render failed" }
      }.to raise_error("render failed")

      expect(Rails.logger).to have_received(:info).with(
        hash_including(
          event: "pdf.performance",
          stage: :document_render,
          duration_ms: 10.0
        )
      )
    end
  end
end
