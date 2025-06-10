class PdfGeneratorService
  class ImageProcessor
    include Configuration

    # Unified QR code generator for any entity
    def self.generate_qr_code_footer(pdf, entity)
      entity_type = entity.class.name.downcase
      qr_code_png = QrCodeService.generate_qr_code(entity)
      qr_code_temp_file = Tempfile.new(["qr_code_#{entity_type}_#{entity.id}_#{Process.pid}", ".png"])

      begin
        qr_code_temp_file.binmode
        qr_code_temp_file.write(qr_code_png)
        qr_code_temp_file.close

        # Position elements in bottom right corner
        photo_entity = entity.is_a?(Inspection) ? entity.unit : entity
        photo_size = QR_CODE_SIZE * 2  # Photo is twice the size of QR code

        # QR code position (bottom right corner)
        qr_x = pdf.bounds.width - QR_CODE_SIZE - QR_CODE_MARGIN
        qr_y = QR_CODE_BOTTOM_OFFSET + QR_CODE_SIZE

        # Photo position (bottom right corner aligned with QR code's bottom right)
        # In Prawn, y-coordinate is the bottom of the image
        photo_x = qr_x + QR_CODE_SIZE - photo_size  # Photo's right edge aligns with QR's right edge
        photo_y = qr_y - QR_CODE_SIZE + photo_size  # Photo's bottom edge aligns with QR's bottom edge

        # Add entity photo first (so it's behind the QR code)
        add_entity_photo_footer(pdf, photo_entity, photo_x, photo_y)

        # Add QR code on top with transparency
        pdf.transparent(0.5) do
          pdf.image qr_code_temp_file.path, at: [qr_x, qr_y], width: QR_CODE_SIZE, height: QR_CODE_SIZE
        end
      ensure
        qr_code_temp_file.close unless qr_code_temp_file.closed?
        qr_code_temp_file.unlink if File.exist?(qr_code_temp_file.path)
      end
    end

    # Process image to handle EXIF orientation data
    def self.process_image_with_orientation(photo)
      # Download the image data
      image_data = photo.download

      # Create a temporary file for ImageProcessing
      temp_file = Tempfile.new(["temp_image_#{Process.pid}", ".jpg"])

      begin
        temp_file.binmode
        temp_file.write(image_data)
        temp_file.close

        # Use ImageProcessing to auto-orient the image based on EXIF data
        processed_image = ImageProcessing::MiniMagick
          .source(temp_file.path)
          .auto_orient
          .call

        # Return the processed image as binary data
        processed_image.read
      ensure
        temp_file.close unless temp_file.closed?
        temp_file.unlink if File.exist?(temp_file.path)
        processed_image&.close if processed_image.respond_to?(:close)
      end
    end

    # Add entity photo in footer area (below QR code)
    def self.add_entity_photo_footer(pdf, entity, x_position, y_position)
      return unless entity&.photo&.attached?

      photo_size = QR_CODE_SIZE * 2  # Twice as big as QR code
      processed_image = process_image_with_orientation(entity.photo)
      pdf.image StringIO.new(processed_image), at: [x_position, y_position], width: photo_size, height: photo_size
    end

    # Add entity photo in header area (top right corner)
    def self.add_entity_photo(pdf, entity, x_position = nil, y_position = nil)
      return unless entity&.photo&.attached?

      # Default position: top right corner
      x_pos = x_position || (pdf.bounds.width - UNIT_PHOTO_X_OFFSET)
      y_pos = y_position || pdf.cursor

      processed_image = process_image_with_orientation(entity.photo)
      pdf.image StringIO.new(processed_image), at: [x_pos, y_pos], width: UNIT_PHOTO_WIDTH, height: UNIT_PHOTO_HEIGHT
    end
  end
end
