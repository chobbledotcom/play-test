# typed: false

class PdfGeneratorService
  class ImageProcessor
    require "vips"
    include Configuration

    def self.generate_qr_code_header(pdf, entity)
      qr_code_png = QrCodeService.generate_qr_code(entity)
      # Position QR code at top left of page
      qr_width, qr_height = PositionCalculator.qr_code_dimensions
      # Use pdf.bounds.top to position from top of page
      image_options = {
        at: [0, pdf.bounds.top],
        width: qr_width,
        height: qr_height
      }
      pdf.image StringIO.new(qr_code_png), image_options
    end

    def self.add_unit_photo_footer(
      pdf,
      unit,
      column_count = 3,
      pdf_type: :unit,
      record_id: unit&.id
    )
      return 0 unless unit&.photo&.blob

      pdf_width = pdf.bounds.width
      attachment = unit.photo
      context = performance_context(attachment).merge(pdf_type:, record_id:)
      image = create_image(attachment, context)
      dimensions = calculate_footer_photo_dimensions(pdf, image, column_count)
      photo_width, photo_height = dimensions

      if photo_height <= 0
        error_message = I18n.t(
          "pdf_generator.errors.zero_photo_height",
          unit_id: unit.id
        )
        raise error_message
      end

      photo_x = pdf_width - photo_width
      photo_y = calculate_photo_y(pdf, photo_height)

      render_processed_image(pdf, image, photo_x, photo_y,
        photo_width, photo_height, attachment, context)

      photo_height
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, attachment)
    end

    def self.process_image_with_orientation(attachment)
      context = performance_context(attachment)
      image = create_image(attachment, context)
      # Images are already orientation-corrected from upload processing
      transcode_to_png(image, context)
    end

    def self.calculate_footer_photo_dimensions(pdf, image, column_count = 3)
      column_width = calculate_column_width(pdf, column_count)
      photo_width = column_width.round
      photo_height = calculate_height_from_aspect(
        photo_width, image.width, image.height
      )

      [photo_width, photo_height]
    end

    def self.calculate_column_width(pdf, column_count)
      spacer_count = column_count - 1
      spacer_width = Configuration::ASSESSMENT_COLUMN_SPACER
      total_spacer_width = spacer_width * spacer_count
      (pdf.bounds.width - total_spacer_width) / column_count.to_f
    end

    def self.calculate_height_from_aspect(photo_width, original_width,
      original_height)
      if original_width.zero? || original_height.zero?
        photo_width
      else
        aspect_ratio = original_width.to_f / original_height.to_f
        (photo_width / aspect_ratio).round
      end
    end

    def self.render_processed_image(pdf, image, x, y, width, height, attachment,
      context)
      # Images are already orientation-corrected from upload processing
      processed_image = transcode_to_png(image, context)

      image_options = {
        at: [x, y],
        width: width,
        height: height
      }
      ImageError.with_error_handling(attachment) do
        PdfPerformance.measure(
          :image_embed,
          **context
        ) do
          pdf.image StringIO.new(processed_image), image_options
        end
      end
    end

    def self.create_image(attachment, context)
      image_data = PdfPerformance.measure(
        :image_download,
        **context
      ) do
        attachment.blob.download
      end
      PdfPerformance.measure(
        :image_decode,
        **context
      ) do
        Vips::Image.new_from_buffer(image_data, "")
      end
    end

    def self.transcode_to_png(image, context)
      PdfPerformance.measure(:image_transcode, **context) do
        image.write_to_buffer(".png")
      end
    end

    def self.calculate_photo_y(pdf, photo_height)
      if pdf.page_number == 1
        Configuration::FOOTER_HEIGHT +
          Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      else
        Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      end
    end

    def self.performance_context(attachment)
      record = attachment.record
      {
        pdf_type: record.class.model_name.singular.to_sym,
        record_id: record.id,
        attachment: attachment.name
      }
    end

    private_class_method :performance_context, :transcode_to_png
  end
end
