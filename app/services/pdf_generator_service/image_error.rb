class PdfGeneratorService
  class ImageError
    def self.build_detailed_error(original_error, attachment)
      blob = attachment.blob
      details = extract_image_details(blob, attachment)
      service_url = build_service_url(blob)

      detailed_message = format_error_message(
        original_error, details, service_url
      )

      original_error.class.new(detailed_message)
    end

    def self.extract_image_details(blob, attachment)
      record = attachment.record
      {
        filename: blob.filename.to_s,
        byte_size: blob.byte_size,
        content_type: blob.content_type,
        record_type: record.class.name,
        record_id: record.try(:serial) || record.try(:id) || "unknown"
      }
    end

    def self.build_service_url(blob)
      default_host = Rails.application.config
        .action_controller.default_url_options[:host] || "localhost"

      Rails.application.routes.url_helpers.rails_blob_url(
        blob, host: default_host
      )
    end

    def self.format_error_message(original_error, details, service_url)
      size_kb = (details[:byte_size] / 1024.0).round(2)

      <<~MESSAGE
        #{original_error.message}

        Image details:
        Filename: #{details[:filename]}
        Size: #{details[:byte_size]} bytes (#{size_kb} KB)
        Content-Type: #{details[:content_type]}
        Record: #{details[:record_type]} #{details[:record_id]}
        ActiveStorage URL: #{service_url}
      MESSAGE
    end

    private_class_method :extract_image_details, :build_service_url,
      :format_error_message
  end
end
