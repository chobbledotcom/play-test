# typed: strict

require "sorbet-runtime"

class PdfCacheService
  extend T::Sig

  CacheResult = Struct.new(:type, :data, keyword_init: true)
  # type: :redirect or :pdf_data
  # data: URL string for redirect, or PDF binary data

  class << self
    extend T::Sig

    sig do
      params(inspection: Inspection, options: T.untyped)
        .returns(CacheResult)
    end
    def fetch_or_generate_inspection_pdf(inspection, **options)
      # Never cache incomplete inspections
      unless caching_enabled? && inspection.complete?
        return generate_pdf_result(inspection, :inspection, **options)
      end

      fetch_or_generate(inspection, :inspection, **options)
    end

    sig { params(unit: Unit, options: T.untyped).returns(CacheResult) }
    def fetch_or_generate_unit_pdf(unit, **options)
      return generate_pdf_result(unit, :unit, **options) unless caching_enabled?

      fetch_or_generate(unit, :unit, **options)
    end

    sig { params(inspection: Inspection).void }
    def invalidate_inspection_cache(inspection)
      invalidate_cache(inspection)
    end

    sig { params(unit: Unit).void }
    def invalidate_unit_cache(unit)
      invalidate_cache(unit)
    end

    private

    sig do
      params(
        record: T.any(Inspection, Unit),
        type: Symbol,
        options: T.untyped
      ).returns(CacheResult)
    end
    def fetch_or_generate(record, type, **options)
      valid_cache = record.cached_pdf.attached? &&
        cached_pdf_valid?(record.cached_pdf, record)

      if valid_cache
        Rails.logger.info "PDF cache hit for #{type} #{record.id}"

        if redirect_to_s3?
          url = generate_signed_url(record.cached_pdf)
          CacheResult.new(type: :redirect, data: url)
        else
          CacheResult.new(type: :stream, data: record.cached_pdf)
        end
      else
        Rails.logger.info "PDF cache miss for #{type} #{record.id}"
        generate_and_cache(record, type, **options)
      end
    end

    sig do
      params(
        record: T.any(Inspection, Unit),
        type: Symbol,
        options: T.untyped
      ).returns(CacheResult)
    end
    def generate_and_cache(record, type, **options)
      result = generate_pdf_result(record, type, **options)
      store_cached_pdf(record, result.data)
      result
    end

    sig do
      params(
        record: T.any(Inspection, Unit),
        type: Symbol,
        options: T.untyped
      ).returns(CacheResult)
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

    sig { params(record: T.any(Inspection, Unit)).void }
    def invalidate_cache(record)
      return unless caching_enabled?

      record.cached_pdf.purge if record.cached_pdf.attached?
    end

    sig { returns(T::Boolean) }
    def caching_enabled?
      pdf_cache_from_date.present?
    end

    sig { params(attachment: T.untyped).returns(String) }
    def generate_signed_url(attachment)
      # Generate a signed URL that expires in 1 hour
      # The URL includes a timestamp in the signed parameters
      attachment.blob.url(expires_in: 1.hour, disposition: "inline")
    end

    sig { returns(T.nilable(Date)) }
    def pdf_cache_from_date
      @pdf_cache_from_date ||= begin
        date_string = ENV["PDF_CACHE_FROM"]
        return nil if date_string.blank?

        Date.parse(date_string)
      rescue ArgumentError
        error_msg = "Invalid PDF_CACHE_FROM date format: #{date_string}. "
        error_msg += "Expected format: YYYY-MM-DD"
        raise ArgumentError, error_msg
      end
    end

    sig do
      params(
        attachment: T.untyped,
        record: T.any(Inspection, Unit)
      ).returns(T::Boolean)
    end
    def cached_pdf_valid?(attachment, record)
      return false unless attachment.blob&.created_at

      cache_created_at = attachment.blob.created_at
      cache_threshold = pdf_cache_from_date.beginning_of_day

      # Check if cache is newer than the threshold date
      return false unless cache_created_at > cache_threshold

      # Check if user assets were updated after cache
      !user_assets_updated_after?(record.user, cache_created_at)
    end

    sig do
      params(
        user: T.nilable(User),
        cache_created_at: T.any(ActiveSupport::TimeWithZone, Date, Time)
      ).returns(T::Boolean)
    end
    def user_assets_updated_after?(user, cache_created_at)
      return false unless user

      if attachment_updated_after?(user.signature, cache_created_at)
        Rails.logger.info "User signature updated after PDF cache"
        return true
      end

      if attachment_updated_after?(user.logo, cache_created_at)
        Rails.logger.info "User logo updated after PDF cache"
        return true
      end

      false
    end

    sig do
      params(
        attachment: T.untyped,
        reference_time: T.any(ActiveSupport::TimeWithZone, Date, Time)
      ).returns(T::Boolean)
    end
    def attachment_updated_after?(attachment, reference_time)
      attachment&.attached? &&
        attachment.blob.created_at > reference_time
    end

    sig do
      params(
        record: T.any(Inspection, Unit),
        pdf_data: String
      ).void
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

    sig { returns(T::Boolean) }
    def redirect_to_s3?
      ActiveModel::Type::Boolean.new.cast(ENV["REDIRECT_TO_S3_PDFS"])
    end
  end
end
