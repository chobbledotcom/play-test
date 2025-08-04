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

        result = described_class.fetch_or_generate_inspection_pdf(inspection)
        expect(result).to eq("pdf_data")
        expect(inspection.cached_pdf.attached?).to be false
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

          result = described_class.fetch_or_generate_inspection_pdf(inspection)
          expect(result).to eq("new_pdf_data")
          
          inspection.reload
          expect(inspection.cached_pdf.attached?).to be true
        end
      end

      context "with a valid cached PDF" do
        before do
          # Attach a cached PDF with a recent date
          inspection.cached_pdf.attach(
            io: StringIO.new("cached_pdf_data"),
            filename: "cached.pdf",
            content_type: "application/pdf"
          )
          inspection.reload
        end

        it "returns the cached PDF" do
          expect(PdfGeneratorService).not_to receive(:generate_inspection_report)

          result = described_class.fetch_or_generate_inspection_pdf(inspection)
          expect(result).to eq("cached_pdf_data")
        end
      end

      context "with an invalid cached PDF (older than PDF_CACHE_FROM)" do
        before do
          # Create a cached PDF with an old date
          inspection.cached_pdf.attach(
            io: StringIO.new("old_cached_pdf"),
            filename: "cached.pdf",
            content_type: "application/pdf"
          )
          inspection.reload
          # Mock the created_at to be before PDF_CACHE_FROM
          allow(inspection.cached_pdf.blob).to receive(:created_at).and_return(Date.parse("2023-01-01"))
        end

        it "generates a new PDF and updates the cache" do
          pdf_document = double(render: "new_pdf_data")
          expect(PdfGeneratorService).to receive(:generate_inspection_report)
            .with(inspection)
            .and_return(pdf_document)

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

        result = described_class.fetch_or_generate_inspection_pdf(inspection)
        expect(result).to eq("pdf_data")
      end
    end

    context "with options passed" do
      before do
        allow(described_class).to receive(:pdf_cache_from_date).and_return(nil)
      end

      it "passes options to PDF generator" do
        options = { debug_enabled: true, debug_queries: ["SELECT 1"] }
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

        result = described_class.fetch_or_generate_unit_pdf(unit)
        expect(result).to eq("unit_pdf_data")
        
        unit.reload
        expect(unit.cached_pdf.attached?).to be true
      end
    end
  end

  describe ".invalidate_inspection_cache" do
    before do
      allow(described_class).to receive(:pdf_cache_from_date).and_return(Date.parse("2024-01-01"))
      inspection.cached_pdf.attach(
        io: StringIO.new("cached_data"),
        filename: "cached.pdf",
        content_type: "application/pdf"
      )
      inspection.reload
    end

    it "purges the cached PDF" do
      expect(inspection.cached_pdf.attached?).to be true
      described_class.invalidate_inspection_cache(inspection)
      
      inspection.reload
      expect(inspection.cached_pdf.attached?).to be false
    end
  end

  describe ".invalidate_unit_cache" do
    before do
      allow(described_class).to receive(:pdf_cache_from_date).and_return(Date.parse("2024-01-01"))
      unit.cached_pdf.attach(
        io: StringIO.new("cached_data"),
        filename: "cached.pdf",
        content_type: "application/pdf"
      )
      unit.reload
    end

    it "purges the cached PDF" do
      expect(unit.cached_pdf.attached?).to be true
      described_class.invalidate_unit_cache(unit)
      
      unit.reload
      expect(unit.cached_pdf.attached?).to be false
    end
  end
end