class PdfCacheService
  CacheResult = Struct.new(:type, :data, keyword_init: true)
  # type: :redirect or :pdf_data
  # data: URL string for redirect, or PDF binary data

  class << self
    def fetch_or_generate_inspection_pdf(inspection, **options)
      unless caching_enabled?
        pdf_data = generate_inspection_pdf(inspection, **options)
        return CacheResult.new(type: :pdf_data, data: pdf_data)
      end

      if inspection.cached_pdf.attached? && cached_pdf_valid?(inspection.cached_pdf)
        Rails.logger.info "PDF cache hit for inspection #{inspection.id}"
        url = generate_signed_url(inspection.cached_pdf)
        CacheResult.new(type: :redirect, data: url)
      else
        Rails.logger.info "PDF cache miss for inspection #{inspection.id}"
        pdf_data = generate_inspection_pdf(inspection, **options)
        store_cached_pdf(inspection, pdf_data)
        CacheResult.new(type: :pdf_data, data: pdf_data)
      end
    end

    def fetch_or_generate_unit_pdf(unit, **options)
      unless caching_enabled?
        pdf_data = generate_unit_pdf(unit, **options)
        return CacheResult.new(type: :pdf_data, data: pdf_data)
      end

      if unit.cached_pdf.attached? && cached_pdf_valid?(unit.cached_pdf)
        Rails.logger.info "PDF cache hit for unit #{unit.id}"
        url = generate_signed_url(unit.cached_pdf)
        CacheResult.new(type: :redirect, data: url)
      else
        Rails.logger.info "PDF cache miss for unit #{unit.id}"
        pdf_data = generate_unit_pdf(unit, **options)
        store_cached_pdf(unit, pdf_data)
        CacheResult.new(type: :pdf_data, data: pdf_data)
      end
    end

    def invalidate_inspection_cache(inspection)
      return unless caching_enabled?

      inspection.cached_pdf.purge if inspection.cached_pdf.attached?
    end

    def invalidate_unit_cache(unit)
      return unless caching_enabled?

      unit.cached_pdf.purge if unit.cached_pdf.attached?
    end

    private

    def caching_enabled?
      pdf_cache_from_date.present?
    end

    def generate_signed_url(attachment)
      # Generate a signed URL that expires in 1 hour
      # The URL includes a timestamp in the signed parameters
      attachment.blob.url(expires_in: 1.hour, disposition: "inline")
    end

    def pdf_cache_from_date
      @pdf_cache_from_date ||= begin
        date_string = ENV["PDF_CACHE_FROM"]
        return nil if date_string.blank?

        Date.parse(date_string)
      rescue ArgumentError
        Rails.logger.error "Invalid PDF_CACHE_FROM date format: #{date_string}"
        nil
      end
    end

    def cached_pdf_valid?(attachment)
      return false unless attachment.blob&.created_at

      attachment.blob.created_at.to_date > pdf_cache_from_date
    end

    def store_cached_pdf(record, pdf_data)
      # Purge old cached PDF if exists
      record.cached_pdf.purge if record.cached_pdf.attached?

      # Store new cached PDF
      filename = if record.is_a?(Inspection)
        "inspection_#{record.id}_cached_#{Time.current.to_i}.pdf"
      else
        "unit_#{record.id}_cached_#{Time.current.to_i}.pdf"
      end

      # Create a StringIO with proper positioning
      io = StringIO.new(pdf_data)
      io.rewind

      record.cached_pdf.attach(
        io: io,
        filename: filename,
        content_type: "application/pdf"
      )
    end

    def generate_inspection_pdf(inspection, **options)
      pdf_document = if options.any?
        PdfGeneratorService.generate_inspection_report(inspection, **options)
      else
        PdfGeneratorService.generate_inspection_report(inspection)
      end
      pdf_document.render
    end

    def generate_unit_pdf(unit, **options)
      pdf_document = if options.any?
        PdfGeneratorService.generate_unit_report(unit, **options)
      else
        PdfGeneratorService.generate_unit_report(unit)
      end
      pdf_document.render
    end
  end
end
