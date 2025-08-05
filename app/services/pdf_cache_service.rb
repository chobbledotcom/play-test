class PdfCacheService
  CacheResult = Struct.new(:type, :data, keyword_init: true)
  # type: :redirect or :pdf_data
  # data: URL string for redirect, or PDF binary data

  class << self
    def fetch_or_generate_inspection_pdf(inspection, **options)
      # Never cache incomplete inspections
      return generate_pdf_result(inspection, :inspection, **options) unless caching_enabled? && inspection.complete?

      fetch_or_generate(inspection, :inspection, **options)
    end

    def fetch_or_generate_unit_pdf(unit, **options)
      return generate_pdf_result(unit, :unit, **options) unless caching_enabled?

      fetch_or_generate(unit, :unit, **options)
    end

    def invalidate_inspection_cache(inspection)
      invalidate_cache(inspection)
    end

    def invalidate_unit_cache(unit)
      invalidate_cache(unit)
    end

    private

    def fetch_or_generate(record, type, **options)
      if record.cached_pdf.attached? && cached_pdf_valid?(record.cached_pdf)
        Rails.logger.info "PDF cache hit for #{type} #{record.id}"
        url = generate_signed_url(record.cached_pdf)
        CacheResult.new(type: :redirect, data: url)
      else
        Rails.logger.info "PDF cache miss for #{type} #{record.id}"
        generate_and_cache(record, type, **options)
      end
    end

    def generate_and_cache(record, type, **options)
      result = generate_pdf_result(record, type, **options)
      store_cached_pdf(record, result.data)
      result
    end

    def generate_pdf_result(record, type, **options)
      pdf_document = case type
      when :inspection
        PdfGeneratorService.generate_inspection_report(record, **options)
      when :unit
        PdfGeneratorService.generate_unit_report(record, **options)
      end

      CacheResult.new(type: :pdf_data, data: pdf_document.render)
    end

    def invalidate_cache(record)
      return unless caching_enabled?

      record.cached_pdf.purge if record.cached_pdf.attached?
    end

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
        raise ArgumentError, "Invalid PDF_CACHE_FROM date format: #{date_string}. Expected format: YYYY-MM-DD"
      end
    end

    def cached_pdf_valid?(attachment)
      return false unless attachment.blob&.created_at

      attachment.blob.created_at > pdf_cache_from_date.beginning_of_day
    end

    def store_cached_pdf(record, pdf_data)
      # Purge old cached PDF if exists
      record.cached_pdf.purge if record.cached_pdf.attached?

      # Store new cached PDF
      type_name = record.class.name.downcase
      filename = "#{type_name}_#{record.id}_cached_#{Time.current.to_i}.pdf"

      # Create a StringIO with proper positioning
      io = StringIO.new(pdf_data)
      io.rewind

      record.cached_pdf.attach(
        io: io,
        filename: filename,
        content_type: "application/pdf"
      )
    end
  end
end
