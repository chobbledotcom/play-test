# typed: false

class ImageProcessorService
  FULL_SIZE = 1200
  THUMBNAIL_SIZE = 200
  DEFAULT_SIZE = 800

  def self.thumbnail(image)
    return nil unless image&.attached?

    image.variant(
      format: :jpeg,
      resize_to_limit: [THUMBNAIL_SIZE, THUMBNAIL_SIZE],
      saver: {quality: 75}
    )
  end

  def self.default(image)
    return nil unless image&.attached?

    image.variant(
      format: :jpeg,
      resize_to_limit: [DEFAULT_SIZE, DEFAULT_SIZE],
      saver: {quality: 75}
    )
  end

  # Calculate actual dimensions after resize_to_limit transformation
  # Pass in metadata hash with "width" and "height" keys
  # Size can be :full, :thumbnail, or :default (defaults to :default)
  def self.calculate_dimensions(metadata, size = :default)
    max_size = max_size_for(size)
    original_width = metadata["width"].to_f
    original_height = metadata["height"].to_f

    resize_dimensions(original_width, original_height, max_size)
  end

  def self.max_size_for(size)
    case size
    when :full then FULL_SIZE
    when :thumbnail then THUMBNAIL_SIZE
    else DEFAULT_SIZE
    end
  end

  def self.resize_dimensions(original_width, original_height, max_size)
    ratio = max_size / [original_width, original_height].max

    if ratio < 1
      {
        width: (original_width * ratio).round,
        height: (original_height * ratio).round
      }
    else
      {width: original_width.to_i, height: original_height.to_i}
    end
  end
end
