class PdfGeneratorService
  class ImageOrientationProcessor
    require "mini_magick"
    # Process image to handle EXIF orientation data
    def self.process_with_orientation(photo)
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

    # Get image dimensions after applying EXIF orientation correction
    def self.get_dimensions(photo)
      image_data = photo.download
      temp_file = Tempfile.new(["temp_image_#{Process.pid}", ".jpg"])

      begin
        temp_file.binmode
        temp_file.write(image_data)
        temp_file.close

        # Apply auto-orient to get the corrected dimensions
        image = MiniMagick::Image.open(temp_file.path)
        image.auto_orient
        [image.width, image.height]
      ensure
        temp_file.close unless temp_file.closed?
        temp_file.unlink if File.exist?(temp_file.path)
      end
    end

    # Check if image needs orientation correction
    def self.needs_orientation_correction?(photo)
      image_data = photo.download
      temp_file = Tempfile.new(["temp_image_#{Process.pid}", ".jpg"])

      begin
        temp_file.binmode
        temp_file.write(image_data)
        temp_file.close

        image = MiniMagick::Image.open(temp_file.path)
        orientation = image.exif["Orientation"]

        # Orientations 2-8 need correction, 1 is normal
        orientation ? orientation.to_i > 1 : false
      rescue
        # If we can't read EXIF data, assume no correction needed
        false
      ensure
        temp_file.close unless temp_file.closed?
        temp_file.unlink if File.exist?(temp_file.path)
      end
    end
  end
end
