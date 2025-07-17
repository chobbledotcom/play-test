class PdfGeneratorService
  class ImageOrientationProcessor
    require "mini_magick"

    # Process image to handle EXIF orientation data
    def self.process_with_orientation(image)
      image.auto_orient
      image.to_blob
    end

    # Get image dimensions after applying EXIF orientation correction
    def self.get_dimensions(image)
      image = image.dup
      image.auto_orient
      [ image.width, image.height ]
    end

    # Check if image needs orientation correction
    def self.needs_orientation_correction?(image)
      orientation = image.exif["Orientation"]
      # Orientations 2-8 need correction, 1 is normal
      orientation ? orientation.to_i > 1 : false
    end
  end
end
