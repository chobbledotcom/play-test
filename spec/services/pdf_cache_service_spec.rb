# typed: false

require "rails_helper"

RSpec.describe PdfCacheService, type: :service do
  let(:inspection) { create(:inspection, :completed) }
  let(:incomplete_inspection) { create(:inspection) }
  let(:unit) { create(:unit) }

  shared_context "with caching enabled" do
    before do
      Rails.configuration.pdf_cache_enabled = true
      allow(described_class)
        .to receive(:pdf_cache_from_date)
        .and_return(Date.parse("2024-01-01"))
    end
  end

  shared_context "with caching disabled" do
    before do
      Rails.configuration.pdf_cache_enabled = false
      allow(described_class).to receive(:pdf_cache_from_date).and_return(nil)
    end
  end

  # Test helpers for reducing repetition
  define_method(:expect_pdf_result) do |result, type:, data:|
    expect(result).to be_a(PdfCacheService::CacheResult)
    expect(result.type).to eq(type)
    expect(result.data).to eq(data)
  end

  define_method(:mock_cached_pdf) do |record, created_at: Date.parse("2024-02-01"), attached: true|
    cached_pdf = double("cached_pdf")
    allow(record).to receive(:cached_pdf).and_return(cached_pdf)
    allow(cached_pdf).to receive(:attached?).and_return(attached)
    if attached
      blob = double("blob", created_at: created_at)
      allow(cached_pdf).to receive(:blob).and_return(blob)
      allow(cached_pdf).to receive(:download).and_return("cached_pdf_data")
    end
    cached_pdf
  end

  define_method(:mock_user_assets) do |user, signature_attached: false, logo_attached: false, asset_date: nil|
    signature = double(attached?: signature_attached)
    logo = double(attached?: logo_attached)

    if signature_attached && asset_date
      signature_blob = double(created_at: asset_date)
      allow(signature).to receive(:blob).and_return(signature_blob)
    end

    if logo_attached && asset_date
      logo_blob = double(created_at: asset_date)
      allow(logo).to receive(:blob).and_return(logo_blob)
    end

    allow(user).to receive(:signature).and_return(signature)
    allow(user).to receive(:logo).and_return(logo)
  end

  define_method(:expect_pdf_generation_and_caching) do |service_method, record, data = "new_pdf_data"|
    pdf_document = double(render: data)
    expect(PdfGeneratorService).to receive(service_method).with(record).and_return(pdf_document)
    expect(described_class).to receive(:store_cached_pdf).with(record, data)
    pdf_document
  end

  describe ".fetch_or_generate_inspection_pdf" do
    context "when caching is disabled (PDF_CACHE_FROM not set)" do
      include_context "with caching disabled"

      it "generates a new PDF without caching" do
        expect(PdfGeneratorService).to receive(:generate_inspection_report)
          .with(inspection).and_return(double(render: "pdf_data"))
        expect(described_class).not_to receive(:store_cached_pdf)

        result = described_class.fetch_or_generate_inspection_pdf(inspection)
        expect_pdf_result(result, type: :pdf_data, data: "pdf_data")
      end
    end

    context "when caching is enabled" do
      include_context "with caching enabled"

      context "with incomplete inspection" do
        it "generates PDF without caching" do
          expect(PdfGeneratorService).to receive(:generate_inspection_report)
            .with(incomplete_inspection).and_return(double(render: "pdf_data"))
          expect(described_class).not_to receive(:store_cached_pdf)

          result = described_class.fetch_or_generate_inspection_pdf(incomplete_inspection)
          expect_pdf_result(result, type: :pdf_data, data: "pdf_data")
        end
      end

      context "with no cached PDF" do
        it "generates and caches a new PDF" do
          expect_pdf_generation_and_caching(:generate_inspection_report, inspection, "new_pdf_data")

          result = described_class.fetch_or_generate_inspection_pdf(inspection)
          expect_pdf_result(result, type: :pdf_data, data: "new_pdf_data")
        end
      end

      context "with a valid cached PDF" do
        let(:user) { inspection.user }

        before do
          mock_cached_pdf(inspection)
          mock_user_assets(user)
        end

        context "when REDIRECT_TO_S3_PDFS is false" do
          before do
            Rails.configuration.redirect_to_s3_pdfs = false
          end

          it "returns a stream with the cached PDF attachment" do
            expect(PdfGeneratorService).not_to receive(:generate_inspection_report)

            result = described_class.fetch_or_generate_inspection_pdf(inspection)
            expect(result).to be_a(PdfCacheService::CacheResult)
            expect(result.type).to eq(:stream)
            expect(result.data).to eq(inspection.cached_pdf)
          end
        end

        context "when REDIRECT_TO_S3_PDFS is true" do
          before do
            Rails.configuration.redirect_to_s3_pdfs = true
          end

          it "returns a redirect to the cached PDF" do
            expect(PdfGeneratorService).not_to receive(:generate_inspection_report)
            expect(described_class).to receive(:generate_signed_url).and_return("https://example.com/signed-url")

            result = described_class.fetch_or_generate_inspection_pdf(inspection)
            expect(result).to be_a(PdfCacheService::CacheResult)
            expect(result.type).to eq(:redirect)
            expect(result.data).to eq("https://example.com/signed-url")
          end
        end

        %i[signature logo].each do |asset_type|
          context "when user #{asset_type} is updated after cache" do
            before do
              mock_user_assets(user, "#{asset_type}_attached": true, asset_date: Date.parse("2024-03-01"))
            end

            it "regenerates the PDF" do
              expect_pdf_generation_and_caching(:generate_inspection_report, inspection)

              result = described_class.fetch_or_generate_inspection_pdf(inspection)
              expect_pdf_result(result, type: :pdf_data, data: "new_pdf_data")
            end
          end
        end
      end

      context "with an invalid cached PDF (older than PDF_CACHE_FROM)" do
        before do
          cached_pdf = mock_cached_pdf(inspection, created_at: Date.parse("2023-01-01"))
          allow(cached_pdf).to receive(:purge)
        end

        it "generates a new PDF and updates the cache" do
          expect_pdf_generation_and_caching(:generate_inspection_report, inspection)

          result = described_class.fetch_or_generate_inspection_pdf(inspection)
          expect_pdf_result(result, type: :pdf_data, data: "new_pdf_data")
        end
      end
    end

    context "with options passed" do
      include_context "with caching disabled"

      it "passes options to PDF generator" do
        options = {debug_enabled: true, debug_queries: ["SELECT 1"]}
        expect(PdfGeneratorService).to receive(:generate_inspection_report)
          .with(inspection, **options).and_return(double(render: "pdf_data"))

        result = described_class.fetch_or_generate_inspection_pdf(inspection, **options)
        expect_pdf_result(result, type: :pdf_data, data: "pdf_data")
      end
    end
  end

  describe ".fetch_or_generate_unit_pdf" do
    context "when caching is enabled" do
      include_context "with caching enabled"

      it "generates and caches a new PDF when no cache exists" do
        pdf_document = double(render: "unit_pdf_data")
        expect(PdfGeneratorService)
          .to receive(:generate_unit_report)
          .with(unit)
          .and_return(pdf_document)

        expect(described_class)
          .to receive(:store_cached_pdf)
          .with(unit, "unit_pdf_data")

        result = described_class.fetch_or_generate_unit_pdf(unit)
        expect(result).to be_a(PdfCacheService::CacheResult)
        expect(result.type).to eq(:pdf_data)
        expect(result.data).to eq("unit_pdf_data")
      end

      context "with cached PDF and updated user assets" do
        let(:user) { unit.user }

        before do
          # Mock a cached PDF attachment
          cached_pdf = double("cached_pdf")
          allow(unit).to receive(:cached_pdf).and_return(cached_pdf)
          allow(cached_pdf).to receive(:attached?).and_return(true)
          blob = double("blob", created_at: Date.parse("2024-02-01"))
          allow(cached_pdf).to receive(:blob).and_return(blob)

          # Mock user without attachments by default
          allow(user).to receive(:signature)
            .and_return(double(attached?: false))
          allow(user).to receive(:logo)
            .and_return(double(attached?: false))
        end

        context "when user logo is updated after cache" do
          before do
            # Mock logo attachment with newer date than cache
            logo = double("logo")
            allow(user).to receive(:logo).and_return(logo)
            allow(logo).to receive(:attached?).and_return(true)
            logo_blob = double(
              "logo_blob",
              created_at: Date.parse("2024-03-01")
            )
            allow(logo).to receive(:blob).and_return(logo_blob)
          end

          it "regenerates the PDF" do
            pdf_document = double(render: "new_pdf_data")
            expect(PdfGeneratorService)
              .to receive(:generate_unit_report)
              .with(unit)
              .and_return(pdf_document)
            expect(described_class)
              .to receive(:store_cached_pdf)
              .with(unit, "new_pdf_data")

            result = described_class.fetch_or_generate_unit_pdf(unit)
            expect(result).to be_a(PdfCacheService::CacheResult)
            expect(result.type).to eq(:pdf_data)
            expect(result.data).to eq("new_pdf_data")
          end
        end
      end
    end
  end

  describe ".invalidate_inspection_cache" do
    context "when caching is enabled" do
      include_context "with caching enabled"

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
      include_context "with caching disabled"

      it "does nothing" do
        expect(inspection.cached_pdf).not_to receive(:purge)
        described_class.invalidate_inspection_cache(inspection)
      end
    end
  end

  describe ".invalidate_unit_cache" do
    context "when caching is enabled" do
      include_context "with caching enabled"

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

  describe ".generate_signed_url" do
    it "generates a signed URL with 1 hour expiration" do
      # Mock the attachment and blob
      cached_pdf = double("cached_pdf")
      blob = double("blob")
      allow(cached_pdf).to receive(:blob).and_return(blob)

      expect(blob).to receive(:url).with(expires_in: 1.hour, disposition: "inline").and_return("https://example.com/signed-url")

      url = described_class.send(:generate_signed_url, cached_pdf)
      expect(url).to eq("https://example.com/signed-url")
    end
  end
end
