class PdfGeneratorService
  class ImageProcessor
    include Configuration

    def self.generate_qr_code_footer(pdf, entity)
      qr_code_png = QrCodeService.generate_qr_code(entity)
      render_qr_code_with_photo(pdf, entity, qr_code_png)
    end

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

    def self.render_qr_code_with_photo(pdf, entity, qr_code_png)
      photo_entity = entity.is_a?(Inspection) ? entity.unit : entity
      qr_x, qr_y = PositionCalculator.qr_code_position(pdf.bounds.width, pdf.page_number)

      add_entity_photo_footer(pdf, photo_entity, qr_x, qr_y)
      add_qr_code_overlay(pdf, qr_code_png, qr_x, qr_y)
    end

    def self.add_qr_code_overlay(pdf, qr_code_png, qr_x, qr_y)
      # Render at 100% opacity (removed transparent wrapper)
      qr_width, qr_height = PositionCalculator.qr_code_dimensions
      image_options = {
        at: [qr_x, qr_y],
        width: qr_width,
        height: qr_height
      }
      pdf.image StringIO.new(qr_code_png), image_options
    end

    def self.process_image_with_orientation(attachment)
      image = create_image(attachment)
      ImageOrientationProcessor.process_with_orientation(image)
    end

    def self.add_entity_photo_footer(pdf, entity, qr_x, qr_y)
      return unless entity&.photo

      attachment = entity.photo
      return unless attachment.blob

      render_entity_photo(pdf, attachment, qr_x, qr_y)
    end

    def self.render_entity_photo(pdf, attachment, qr_x, qr_y)
      image_data = attachment.blob.download
      image = MiniMagick::Image.read(image_data)

      dimensions = calculate_footer_photo_dimensions(image)
      photo_width, photo_height = dimensions

      positions = PositionCalculator.photo_footer_position(
        qr_x, qr_y, photo_width, photo_height
      )
      photo_x, photo_y = positions

      render_processed_image(
        pdf, image, photo_x, photo_y, photo_width, photo_height, attachment
      )
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, attachment)
    end

    def self.calculate_footer_photo_dimensions(image)
      original_width = image.width
      original_height = image.height
      PositionCalculator.footer_photo_dimensions(
        original_width, original_height
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
