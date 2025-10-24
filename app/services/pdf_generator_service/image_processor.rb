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

    def self.add_unit_photo_footer(pdf, unit, column_count = 3)
      return unless unit&.photo&.blob

      attachment = unit.photo
      image = create_image(attachment)
      dimensions = calculate_footer_photo_dimensions(pdf, image, column_count)
      photo_width, photo_height = dimensions

      position_and_render_photo(
        pdf,
        image,
        photo_width,
        photo_height,
        attachment
      )
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, attachment)
    end

    def self.position_and_render_photo(
      pdf,
      image,
      photo_width,
      photo_height,
      attachment
    )
      photo_x = pdf.bounds.width - photo_width
      photo_y = calculate_photo_y(pdf, photo_height)

      render_processed_image(
        pdf,
        image,
        photo_x,
        photo_y,
        photo_width,
        photo_height,
        attachment
      )
    end

    def self.measure_unit_photo_height(pdf, unit, column_count = 3)
      return 0 unless unit&.photo&.blob

      attachment = unit.photo
      image = create_image(attachment)
      dimensions = calculate_footer_photo_dimensions(pdf, image, column_count)
      _photo_width, photo_height = dimensions

      if photo_height <= 0
        raise I18n.t("pdf_generator.errors.zero_photo_height", unit_id: unit.id)
      end

      photo_height
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, attachment)
    end

    def self.process_image_with_orientation(attachment)
      image = create_image(attachment)
      # Vips automatically handles EXIF orientation
      image.write_to_buffer(".png")
    end

    def self.calculate_footer_photo_dimensions(pdf, image, column_count = 3)
      photo_width = calculate_column_width(pdf.bounds.width, column_count)
      photo_height = calculate_photo_height(
        image.width,
        image.height,
        photo_width
      )
      [photo_width, photo_height]
    end

    def self.calculate_column_width(pdf_width, column_count)
      spacer_count = column_count - 1
      spacer_width = Configuration::ASSESSMENT_COLUMN_SPACER
      total_spacer_width = spacer_width * spacer_count
      ((pdf_width - total_spacer_width) / column_count.to_f).round
    end

    def self.calculate_photo_height(
      original_width,
      original_height,
      photo_width
    )
      return photo_width if original_width.zero? || original_height.zero?

      aspect_ratio = original_width.to_f / original_height.to_f
      (photo_width / aspect_ratio).round
    end

    def self.render_processed_image(pdf, image, x, y, width, height, attachment)
      # Vips automatically handles EXIF orientation
      processed_image = image.write_to_buffer(".png")

      image_options = {
        at: [x, y],
        width: width,
        height: height
      }
      pdf.image StringIO.new(processed_image), image_options
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, attachment)
    end

    def self.create_image(attachment)
      image_data = attachment.blob.download
      Vips::Image.new_from_buffer(image_data, "")
    end

    def self.calculate_photo_y(pdf, photo_height)
      if pdf.page_number == 1
        Configuration::FOOTER_HEIGHT +
          Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      else
        Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      end
    end
  end
end
