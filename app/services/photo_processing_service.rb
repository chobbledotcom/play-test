class PhotoProcessingService
  require "mini_magick"

  # Process uploaded photo data: resize to max 1200px, convert to JPEG 75% quality, apply EXIF orientation
  def self.process_upload_data(image_data, original_filename = "photo")
    return nil if image_data.blank?

    begin
      # Create MiniMagick image from data
      image = MiniMagick::Image.read(image_data)

      # Apply EXIF orientation correction first
      image.auto_orient

      # Resize to maximum 1200px on longest side
      image.resize "#{ImageProcessorService::FULL_SIZE}x#{ImageProcessorService::FULL_SIZE}>"

      # Replace transparency with white background before converting to JPEG
      image.combine_options do |c|
        c.background "white"
        c.alpha "remove"
        c.alpha "off"
      end

      # Convert to JPEG with 75% quality
      image.format "jpeg"
      image.quality "75"

      # Get processed image data
      processed_data = image.to_blob

      # Create a new StringIO object with processed data
      processed_io = StringIO.new(processed_data)
      # Add custom attributes by defining singleton methods
      processed_filename = change_extension_to_jpg(original_filename)
      processed_io.define_singleton_method(:original_filename) { processed_filename }
      processed_io.define_singleton_method(:content_type) { "image/jpeg" }

      processed_io
    rescue => e
      Rails.logger.error "Photo processing failed: #{e.message}"
      nil
    end
  end

  # Process uploaded file (for backward compatibility)
  def self.process_upload(uploaded_file)
    return nil if uploaded_file.blank?
    process_upload_data(uploaded_file.read, uploaded_file.original_filename)
  end

  # Validate that data is a processable image
  def self.valid_image_data?(image_data)
    return false if image_data.blank?

    image = MiniMagick::Image.read(image_data)
    # Try to get basic image properties to ensure it's valid
    image.width && image.height
    true
  rescue MiniMagick::Error, MiniMagick::Invalid
    false
  end

  # Validate that uploaded file is a processable image
  def self.valid_image?(uploaded_file)
    return false if uploaded_file.blank?
    valid_image_data?(uploaded_file.read)
  end

  def self.change_extension_to_jpg(filename)
    return "photo.jpg" if filename.blank?

    basename = File.basename(filename, ".*")
    "#{basename}.jpg"
  end

  private_class_method :change_extension_to_jpg
end
