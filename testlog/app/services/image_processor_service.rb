class ImageProcessorService
  def self.process(image, max_size = 1200)
    return nil unless image.attached?

    image.variant(
      format: :jpeg,
      resize_to_limit: [max_size, max_size],
      saver: {quality: 75}
    )
  end
end
