# typed: true
# frozen_string_literal: true

require "vips"

module ImageProcessable
  extend ActiveSupport::Concern
  extend T::Sig

  included do
    rescue_from ApplicationErrors::NotAnImageError do |exception|
      handle_image_error(exception)
    end

    rescue_from ApplicationErrors::ImageProcessingError do |exception|
      handle_image_error(exception)
    end
  end

  private

  sig {
    params(
      params_hash: T.any(ActionController::Parameters,
        T::Hash[T.untyped, T.untyped]),
      image_fields: T.untyped
    ).returns(T.any(ActionController::Parameters,
      T::Hash[T.untyped, T.untyped]))
  }
  def process_image_params(params_hash, *image_fields)
    image_fields.each do |field|
      next if params_hash[field].blank?

      uploaded_file = params_hash[field]
      next unless uploaded_file.respond_to?(:read)

      begin
        processed_io = process_image(uploaded_file)
        params_hash[field] = processed_io if processed_io
      rescue ApplicationErrors::NotAnImageError,
        ApplicationErrors::ImageProcessingError => e
        @image_processing_error = e
        params_hash[field] = nil
      end
    end

    params_hash
  end

  sig { params(uploaded_file: T.untyped).returns(T.untyped) }
  def process_image(uploaded_file)
    validate_image!(uploaded_file)

    processed_io = PhotoProcessingService.process_upload(uploaded_file)
    raise ApplicationErrors::ImageProcessingError unless processed_io

    processed_io
  rescue Vips::Error => e
    Rails.logger.error "Image processing failed: #{e.message}"
    error_message = I18n.t("errors.messages.image_processing_error",
      error: e.message)
    raise ApplicationErrors::ImageProcessingError, error_message
  end

  sig { params(uploaded_file: T.untyped).void }
  def validate_image!(uploaded_file)
    return if PhotoProcessingService.valid_image?(uploaded_file)
    raise ApplicationErrors::NotAnImageError
  end

  sig { params(exception: StandardError).void }
  def handle_image_error(exception)
    respond_to do |format|
      format.html do
        flash[:alert] = exception.message
        redirect_back(fallback_location: root_path)
      end
      format.turbo_stream do
        flash.now[:alert] = exception.message
        # For turbo_stream, we just need to redirect back with the flash message
        # The application layout will handle rendering the flash
        redirect_back(fallback_location: root_path, status: :see_other)
      end
    end
  end
end
