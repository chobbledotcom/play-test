class PdfGeneratorService
  class ImageProcessor
    include Configuration

    def self.generate_qr_code_footer(pdf, entity, column_count = 3)
      qr_code_png = QrCodeService.generate_qr_code(entity)
      render_qr_code_with_photo(pdf, entity, qr_code_png, column_count)
    end

    def self.render_qr_code_with_photo(pdf, entity, qr_code_png, column_count = 3)
      photo_entity = entity.is_a?(Inspection) ? entity.unit : entity
      qr_x, qr_y = PositionCalculator.qr_code_position(pdf.bounds.width, pdf.page_number)

      add_entity_photo_footer(pdf, photo_entity, qr_x, qr_y, column_count)
      add_qr_code_overlay(pdf, qr_code_png, qr_x, qr_y)
    end

    def self.add_qr_code_overlay(pdf, qr_code_png, qr_x, qr_y)
      pdf.transparent(0.5) do
        qr_width, qr_height = PositionCalculator.qr_code_dimensions
        image_options = {
          at: [qr_x, qr_y],
          width: qr_width,
          height: qr_height
        }
        pdf.image StringIO.new(qr_code_png), image_options
      end
    end

    def self.process_image_with_orientation(attachment)
      image = create_image(attachment)
      ImageOrientationProcessor.process_with_orientation(image)
    end

    def self.add_entity_photo_footer(pdf, entity, qr_x, qr_y, column_count = 3)
      return unless entity&.photo

      attachment = entity.photo
      return unless attachment.blob

      render_entity_photo(pdf, attachment, qr_x, qr_y, column_count)
    end

    def self.render_entity_photo(pdf, attachment, qr_x, qr_y, column_count = 3)
      image_data = attachment.blob.download
      image = MiniMagick::Image.read(image_data)

      dimensions = calculate_footer_photo_dimensions(image, column_count)
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

    def self.calculate_footer_photo_dimensions(image, column_count = 3)
      original_width = image.width
      original_height = image.height

      # Adjust photo width based on column count
      # For 3 columns: width = 2x QR size
      # For 4 columns: width = 1.5x QR size (smaller to fit with more columns)
      width_multiplier = (column_count == 4) ? 1.5 : 2.0

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
