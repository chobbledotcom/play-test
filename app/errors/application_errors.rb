# typed: false

module ApplicationErrors
  class NotAnImageError < StandardError
    def initialize(message = nil)
      super(message || I18n.t("errors.messages.invalid_image_format"))
    end
  end

  class ImageProcessingError < StandardError
    def initialize(message = nil)
      super(message || I18n.t("errors.messages.image_processing_failed"))
    end
  end
end
