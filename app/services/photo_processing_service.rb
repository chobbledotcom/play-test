# typed: false

class PhotoProcessingService
  require "vips"

  MAX_UPLOAD_BYTES = 30.megabytes
  MAX_IMAGE_DIMENSION = 20_000
  MAX_IMAGE_PIXELS = 40_000_000

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
    return false if image_data.bytesize > MAX_UPLOAD_BYTES

    image = Vips::Image.new_from_buffer(image_data, "")
    acceptable_dimensions?(image)
  rescue Vips::Error
    false
  end

  def self.valid_image?(uploaded_file)
    return false if uploaded_file.blank?
    return false unless upload_within_size_limit?(uploaded_file)

    tempfile = uploaded_file.tempfile if uploaded_file.respond_to?(:tempfile)
    if tempfile&.respond_to?(:path)
      image = Vips::Image.new_from_file(tempfile.path, access: :sequential)
      return acceptable_dimensions?(image)
    end

    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)

    data = uploaded_file.read
    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)

    valid_image_data?(data)
  rescue Vips::Error
    false
  end

  def self.upload_within_size_limit?(uploaded_file)
    return false if uploaded_file.blank?
    return false unless uploaded_file.respond_to?(:size)

    uploaded_file.size <= MAX_UPLOAD_BYTES
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

  def self.acceptable_dimensions?(image)
    image.width.positive? &&
      image.height.positive? &&
      image.width <= MAX_IMAGE_DIMENSION &&
      image.height <= MAX_IMAGE_DIMENSION &&
      (image.width * image.height) <= MAX_IMAGE_PIXELS
  end

  private_class_method :change_extension_to_jpg, :resize_image,
    :add_white_background, :acceptable_dimensions?
end
