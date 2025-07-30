module ImageProcessable
  extend ActiveSupport::Concern

  included do
    rescue_from ApplicationErrors::NotAnImageError do |exception|
      handle_image_error(exception)
    end

    rescue_from ApplicationErrors::ImageProcessingError do |exception|
      handle_image_error(exception)
    end
  end

  private

  def process_image_params(params_hash, *image_fields)
    image_fields.each do |field|
      next unless params_hash[field].present?

      uploaded_file = params_hash[field]
      next unless uploaded_file.respond_to?(:read)

      begin
        processed_io = process_image(uploaded_file)
        params_hash[field] = processed_io if processed_io
      rescue ApplicationErrors::NotAnImageError, ApplicationErrors::ImageProcessingError => e
        @image_processing_error = e
        params_hash[field] = nil
      end
    end

    params_hash
  end

  def process_image(uploaded_file)
    validate_image!(uploaded_file)

    processed_io = PhotoProcessingService.process_upload(uploaded_file)
    raise ApplicationErrors::ImageProcessingError unless processed_io

    processed_io
  rescue MiniMagick::Error, MiniMagick::Invalid => e
    Rails.logger.error "Image processing failed: #{e.message}"
    error_message = I18n.t("errors.messages.image_processing_error", error: e.message)
    raise ApplicationErrors::ImageProcessingError, error_message
  end

  def validate_image!(uploaded_file)
    return if PhotoProcessingService.valid_image?(uploaded_file)
    raise ApplicationErrors::NotAnImageError
  end

  def handle_image_error(exception)
    respond_to do |format|
      format.html do
        flash[:alert] = exception.message
        redirect_back(fallback_location: root_path)
      end
      format.turbo_stream do
        flash.now[:alert] = exception.message
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
      end
    end
  end
end
