# typed: false
# frozen_string_literal: true

class JsonDateTransformer < Blueprinter::Transformer
  # ISO 8601 date format for JSON API responses
  API_DATE_FORMAT = "%Y-%m-%d"

  def transform(hash, _object, _options)
    transform_value(hash)
  end

  def transform_value(value)
    case value
    when Hash
      value.transform_values { |v| transform_value(v) }
    when Array
      value.map { |v| transform_value(v) }
    when Date, Time, DateTime
      value.strftime(API_DATE_FORMAT)
    when String
      # Handle string timestamps from ActiveRecord
      if /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/.match?(value)
        value.split(" ").first # Extract just the date part
      else
        value
      end
    else
      value
    end
  end
end
