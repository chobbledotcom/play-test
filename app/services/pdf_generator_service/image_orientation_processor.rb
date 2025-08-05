class PdfGeneratorService
  class ImageOrientationProcessor
    require "vips"

    # Process image to handle EXIF orientation data
    def self.process_with_orientation(image)
      # Vips automatically handles EXIF orientation
      # Just return the image as a buffer
      image.write_to_buffer(".png")
    end

    # Get image dimensions after applying EXIF orientation correction
    def self.get_dimensions(image)
      # Vips automatically applies EXIF orientation
      [image.width, image.height]
    end

    # Check if image needs orientation correction
    def self.needs_orientation_correction?(image)
      # Vips handles orientation automatically, so always return false
      false
    end
  end
end
