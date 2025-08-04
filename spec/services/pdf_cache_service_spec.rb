require "rails_helper"

RSpec.describe PdfCacheService, type: :service do
  let(:inspection) { create(:inspection) }
  let(:unit) { create(:unit) }

  describe ".fetch_or_generate_inspection_pdf" do
    context "when caching is disabled (PDF_CACHE_FROM not set)" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(nil)
      end

      it "generates a new PDF without caching" do
        expect(PdfGeneratorService).to receive(:generate_inspection_report)
          .with(inspection)
          .and_return(double(render: "pdf_data"))

        expect(described_class).not_to receive(:store_cached_pdf)

        result = described_class.fetch_or_generate_inspection_pdf(inspection)
        expect(result).to eq("pdf_data")
      end
    end

    context "when caching is enabled" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(Date.parse("2024-01-01"))
      end

      context "with no cached PDF" do
        it "generates and caches a new PDF" do
          pdf_document = double(render: "new_pdf_data")
          expect(PdfGeneratorService).to receive(:generate_inspection_report)
            .with(inspection)
            .and_return(pdf_document)

          expect(described_class).to receive(:store_cached_pdf).with(inspection, "new_pdf_data")

          result = described_class.fetch_or_generate_inspection_pdf(inspection)
          expect(result).to eq("new_pdf_data")
        end
      end

      context "with a valid cached PDF" do
        before do
          # Mock a cached PDF attachment
          cached_pdf = double("cached_pdf")
          allow(inspection).to receive(:cached_pdf).and_return(cached_pdf)
          allow(cached_pdf).to receive(:attached?).and_return(true)
          blob = double("blob", created_at: Date.parse("2024-02-01"))
          allow(cached_pdf).to receive(:blob).and_return(blob)
          allow(cached_pdf).to receive(:download).and_return("cached_pdf_data")
        end

        it "returns the cached PDF" do
          expect(PdfGeneratorService).not_to receive(:generate_inspection_report)

          result = described_class.fetch_or_generate_inspection_pdf(inspection)
          expect(result).to eq("cached_pdf_data")
        end
      end

      context "with an invalid cached PDF (older than PDF_CACHE_FROM)" do
        before do
          # Mock a cached PDF attachment with old date
          cached_pdf = double("cached_pdf")
          allow(inspection).to receive(:cached_pdf).and_return(cached_pdf)
          allow(cached_pdf).to receive(:attached?).and_return(true)
          blob = double("blob", created_at: Date.parse("2023-01-01"))
          allow(cached_pdf).to receive(:blob).and_return(blob)
          allow(cached_pdf).to receive(:purge)
        end

        it "generates a new PDF and updates the cache" do
          pdf_document = double(render: "new_pdf_data")
          expect(PdfGeneratorService).to receive(:generate_inspection_report)
            .with(inspection)
            .and_return(pdf_document)

          expect(described_class).to receive(:store_cached_pdf).with(inspection, "new_pdf_data")

          result = described_class.fetch_or_generate_inspection_pdf(inspection)
          expect(result).to eq("new_pdf_data")
        end
      end
    end

    context "with invalid PDF_CACHE_FROM format" do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PDF_CACHE_FROM").and_return("invalid-date")
      end

      it "logs an error and generates PDF without caching" do
        expect(Rails.logger).to receive(:error).with(/Invalid PDF_CACHE_FROM date format/)
        expect(PdfGeneratorService).to receive(:generate_inspection_report)
          .with(inspection)
          .and_return(double(render: "pdf_data"))

        expect(described_class).not_to receive(:store_cached_pdf)

        result = described_class.fetch_or_generate_inspection_pdf(inspection)
        expect(result).to eq("pdf_data")
      end
    end

    context "with options passed" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(nil)
      end

      it "passes options to PDF generator" do
        options = {debug_enabled: true, debug_queries: ["SELECT 1"]}
        expect(PdfGeneratorService).to receive(:generate_inspection_report)
          .with(inspection, **options)
          .and_return(double(render: "pdf_data"))

        result = described_class.fetch_or_generate_inspection_pdf(inspection, **options)
        expect(result).to eq("pdf_data")
      end
    end
  end

  describe ".fetch_or_generate_unit_pdf" do
    context "when caching is enabled" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(Date.parse("2024-01-01"))
      end

      it "generates and caches a new PDF when no cache exists" do
        pdf_document = double(render: "unit_pdf_data")
        expect(PdfGeneratorService).to receive(:generate_unit_report)
          .with(unit)
          .and_return(pdf_document)

        expect(described_class).to receive(:store_cached_pdf).with(unit, "unit_pdf_data")

        result = described_class.fetch_or_generate_unit_pdf(unit)
        expect(result).to eq("unit_pdf_data")
      end
    end
  end

  describe ".invalidate_inspection_cache" do
    context "when caching is enabled" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(Date.parse("2024-01-01"))
      end

      it "purges the cached PDF if attached" do
        allow(inspection.cached_pdf).to receive(:attached?).and_return(true)
        expect(inspection.cached_pdf).to receive(:purge)

        described_class.invalidate_inspection_cache(inspection)
      end

      it "does nothing if no cached PDF attached" do
        allow(inspection.cached_pdf).to receive(:attached?).and_return(false)
        expect(inspection.cached_pdf).not_to receive(:purge)

        described_class.invalidate_inspection_cache(inspection)
      end
    end

    context "when caching is disabled" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(nil)
      end

      it "does nothing" do
        expect(inspection.cached_pdf).not_to receive(:purge)
        described_class.invalidate_inspection_cache(inspection)
      end
    end
  end

  describe ".invalidate_unit_cache" do
    context "when caching is enabled" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(Date.parse("2024-01-01"))
      end

      it "purges the cached PDF if attached" do
        allow(unit.cached_pdf).to receive(:attached?).and_return(true)
        expect(unit.cached_pdf).to receive(:purge)

        described_class.invalidate_unit_cache(unit)
      end

      it "does nothing if no cached PDF attached" do
        allow(unit.cached_pdf).to receive(:attached?).and_return(false)
        expect(unit.cached_pdf).not_to receive(:purge)

        described_class.invalidate_unit_cache(unit)
      end
    end
  end

  describe ".store_cached_pdf" do
    it "attaches the PDF to the record" do
      # Mock the attachment
      cached_pdf = double("cached_pdf")
      allow(inspection).to receive(:cached_pdf).and_return(cached_pdf)
      allow(cached_pdf).to receive(:attached?).and_return(false)

      expect(cached_pdf).to receive(:attach).with(
        hash_including(
          filename: /inspection_.*_cached_.*\.pdf/,
          content_type: "application/pdf"
        )
      )

      described_class.send(:store_cached_pdf, inspection, "pdf_data")
    end

    it "purges old cached PDF before attaching new one" do
      # Mock the attachment with existing PDF
      cached_pdf = double("cached_pdf")
      allow(inspection).to receive(:cached_pdf).and_return(cached_pdf)
      allow(cached_pdf).to receive(:attached?).and_return(true)

      expect(cached_pdf).to receive(:purge)
      expect(cached_pdf).to receive(:attach)

      described_class.send(:store_cached_pdf, inspection, "pdf_data")
    end
  end
end
