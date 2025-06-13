class ImageProcessorService
  FULL_SIZE = 1200
  THUMBNAIL_SIZE = 200
  DEFAULT_SIZE = 600

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
end
