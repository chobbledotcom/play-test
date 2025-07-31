class PdfGeneratorService
  class PositionCalculator
    include Configuration

    # Calculate QR code position in bottom right corner
    # QR code's bottom-right corner aligns with table right edge, positioned above footer on first page
    def self.qr_code_position(pdf_bounds_width, pdf_page_number = 1)
      x = pdf_bounds_width - QR_CODE_SIZE - QR_CODE_MARGIN
      # On first page, position above footer; on other pages, use standard bottom offset
      y = if pdf_page_number == 1
        Configuration::FOOTER_HEIGHT + QR_CODE_BOTTOM_OFFSET + QR_CODE_SIZE
      else
        QR_CODE_BOTTOM_OFFSET + QR_CODE_SIZE
      end
      [x, y]
    end

    # Calculate photo position aligned with QR code
    # Photo width is twice QR code size, height maintains aspect ratio
    # Photo's bottom-right corner aligns with QR code's bottom-right corner
    def self.photo_footer_position(qr_x, qr_y, photo_width = nil, photo_height = nil)
      photo_width ||= QR_CODE_SIZE * 2
      photo_height ||= photo_width # Default to square if no height provided

      # Photo's right edge aligns with QR's right edge (both align with table right edge)
      photo_x = qr_x + QR_CODE_SIZE - photo_width

      # Photo's bottom edge aligns with QR's bottom edge (both match header spacing)
      photo_y = qr_y - QR_CODE_SIZE + photo_height

      [photo_x, photo_y]
    end

    # Calculate photo dimensions for footer (width = 2x QR size, height maintains aspect ratio)
    # Note: original_width and original_height should be post-EXIF-rotation dimensions
    def self.footer_photo_dimensions(original_width, original_height)
      target_width = QR_CODE_SIZE * 2

      return [target_width, target_width] if original_width.zero? || original_height.zero?

      aspect_ratio = calculate_aspect_ratio(original_width, original_height)
      target_height = (target_width / aspect_ratio).round

      [target_width, target_height]
    end

    # Get QR code dimensions
    def self.qr_code_dimensions
      [QR_CODE_SIZE, QR_CODE_SIZE]
    end

    # Check if coordinates are within PDF bounds
    def self.within_bounds?(x, y, width, height, pdf_bounds_width, pdf_bounds_height)
      x >= 0 &&
        y >= 0 &&
        (x + width) <= pdf_bounds_width &&
        (y + height) <= pdf_bounds_height
    end

    # Calculate aspect ratio for image fitting
    def self.calculate_aspect_ratio(original_width, original_height)
      return 1.0 if original_height.zero?
      original_width.to_f / original_height.to_f
    end

    # Calculate dimensions to fit within constraints while maintaining aspect ratio
    def self.fit_dimensions(original_width, original_height, max_width, max_height)
      return [max_width, max_height] if original_width.zero? || original_height.zero?

      # If original already fits within constraints, return original dimensions
      if original_width <= max_width && original_height <= max_height
        return [original_width, original_height]
      end

      aspect_ratio = calculate_aspect_ratio(original_width, original_height)

      # Try fitting by width first
      fitted_width = max_width
      fitted_height = (fitted_width / aspect_ratio).round

      # If height is too big, fit by height instead
      if fitted_height > max_height
        fitted_height = max_height
        fitted_width = (fitted_height * aspect_ratio).round
      end

      [fitted_width, fitted_height]
    end
  end
end
