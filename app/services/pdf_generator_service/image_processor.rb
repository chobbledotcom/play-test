class PdfGeneratorService
  class ImageProcessor
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
      photo_width, photo_height = calculate_footer_photo_dimensions(image, column_count)

      # Position photo in bottom right corner
      photo_x = pdf_width - photo_width
      # Account for footer height on first page
      photo_y = if pdf.page_number == 1
        Configuration::FOOTER_HEIGHT + Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      else
        Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      end

      render_processed_image(pdf, image, photo_x, photo_y, photo_width, photo_height, attachment)
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, attachment)
    end

    def self.process_image_with_orientation(attachment)
      image = create_image(attachment)
      ImageOrientationProcessor.process_with_orientation(image)
    end

    def self.calculate_footer_photo_dimensions(image, column_count = 3)
      original_width = image.width
      original_height = image.height

      # Adjust photo width based on column count
      # For 3 columns: width = 2x QR size
      # For 4 columns: width = 1.8x QR size (slightly smaller to fit with more columns)
      width_multiplier = (column_count == 4) ? 1.8 : 2.0

      PositionCalculator.footer_photo_dimensions_with_multiplier(
        original_width, original_height, width_multiplier
      )
    end

    def self.render_processed_image(pdf, image, x, y, width, height, attachment)
      image.auto_orient
      processed_image = image.to_blob

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
      MiniMagick::Image.read(image_data)
    end
  end
end
