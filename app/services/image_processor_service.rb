class ImageProcessorService
  FULL_SIZE = 1200
  THUMBNAIL_SIZE = 200
  DEFAULT_SIZE = 800

  def self.full_size(image)
    return nil unless image&.attached?

    image.variant(
      format: :jpeg,
      resize_to_limit: [FULL_SIZE, FULL_SIZE],
      saver: {quality: 75}
    )
  end

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
    max_size = case size
    when :full
      FULL_SIZE
    when :thumbnail
      THUMBNAIL_SIZE
    else
      DEFAULT_SIZE
    end

    original_width = metadata["width"].to_f
    original_height = metadata["height"].to_f

    # Calculate dimensions maintaining aspect ratio with resize_to_limit
    ratio = max_size / [original_width, original_height].max

    # Only scale down if image is larger than max_size
    if ratio < 1
      {width: (original_width * ratio).round, height: (original_height * ratio).round}
    else
      {width: original_width.to_i, height: original_height.to_i}
    end
  end
end
