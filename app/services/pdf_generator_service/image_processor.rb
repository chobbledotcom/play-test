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

      # Calculate photo position in bottom right corner
      pdf_width = pdf.bounds.width

      # Calculate photo dimensions based on column count
      attachment = unit.photo
      image = create_image(attachment)
      dimensions = calculate_footer_photo_dimensions(pdf, image, column_count)
      photo_width, photo_height = dimensions

      # Position photo in bottom right corner
      photo_x = pdf_width - photo_width
      # Account for footer height on first page
      photo_y = calculate_photo_y(pdf, photo_height)

      render_processed_image(pdf, image, photo_x, photo_y,
        photo_width, photo_height, attachment)
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, attachment)
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
      # Images are already orientation-corrected from upload processing
      image.write_to_buffer(".png")
    end

    def self.calculate_footer_photo_dimensions(pdf, image, column_count = 3)
      original_width = image.width
      original_height = image.height

      # Calculate column width based on PDF width and column count
      # Account for column spacers
      spacer_count = column_count - 1
      spacer_width = Configuration::ASSESSMENT_COLUMN_SPACER
      total_spacer_width = spacer_width * spacer_count
      column_width = (pdf.bounds.width - total_spacer_width) / column_count.to_f

      # Photo width equals one column width
      photo_width = column_width.round

      # Calculate height maintaining aspect ratio
      if original_width.zero? || original_height.zero?
        photo_height = photo_width
      else
        aspect_ratio = original_width.to_f / original_height.to_f
        photo_height = (photo_width / aspect_ratio).round
      end

      [photo_width, photo_height]
    end

    def self.render_processed_image(pdf, image, x, y, width, height, attachment)
      # Images are already orientation-corrected from upload processing
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
