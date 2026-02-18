# typed: false

class PhotoProcessingService
  require "vips"

  # Process uploaded photo data: resize to max 1200px, convert to JPEG 75%
  def self.process_upload_data(image_data, original_filename = "photo")
    return nil if image_data.blank?

    begin
      image = Vips::Image.new_from_buffer(image_data, "")
      image = image.autorot
      image = resize_image(image)
      image = add_white_background(image) if image.has_alpha?
      processed_data = image.jpegsave_buffer(Q: 75, strip: true)
      processed_filename = change_extension_to_jpg(original_filename)

      {
        io: StringIO.new(processed_data),
        filename: processed_filename,
        content_type: "image/jpeg"
      }
    rescue => e
      Rails.logger.error "Photo processing failed: #{e.message}"
      nil
    end
  end

  def self.process_upload(uploaded_file)
    return nil if uploaded_file.blank?

    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)

    process_upload_data(uploaded_file.read, uploaded_file.original_filename)
  end

  # Validate that data is a processable image
  def self.valid_image_data?(image_data)
    return false if image_data.blank?

    image = Vips::Image.new_from_buffer(image_data, "")
    # Try to get basic image properties to ensure it's valid
    image.width && image.height
    true
  rescue Vips::Error
    false
  end

  def self.valid_image?(uploaded_file)
    return false if uploaded_file.blank?

    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)

    data = uploaded_file.read
    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)

    valid_image_data?(data)
  end

  def self.change_extension_to_jpg(filename)
    return "photo.jpg" if filename.blank?

    basename = File.basename(filename, ".*")
    "#{basename}.jpg"
  end

  def self.resize_image(image)
    max_size = ImageProcessorService::FULL_SIZE
    return image unless image.width > max_size || image.height > max_size

    scale = [max_size.to_f / image.width, max_size.to_f / image.height].min
    image.resize(scale)
  end

  def self.add_white_background(image)
    background = Vips::Image.black(image.width, image.height).add(255)
    background.composite2(image, :over)
  end

  private_class_method :change_extension_to_jpg, :resize_image,
    :add_white_background
end
