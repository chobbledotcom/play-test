# typed: strict
# frozen_string_literal: true

# Service to verify RPII inspector numbers using the official API
require "net/http"
require "uri"
require "json"

class RpiiVerificationService
  extend T::Sig

  BASE_URL = "https://www.playinspectors.com/wp-admin/admin-ajax.php"
  USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " \
               "AppleWebKit/537.36 (KHTML, like Gecko) " \
               "Chrome/91.0.4472.124 Safari/537.36"

  InspectorInfo = T.type_alias do
    {
      name: T.nilable(String),
      number: T.nilable(String),
      qualifications: T.nilable(String),
      id: T.nilable(String),
      raw_value: String
    }
  end

  VerificationResult = T.type_alias do
    {
      valid: T::Boolean,
      inspector: T.nilable(InspectorInfo)
    }
  end

  class << self
    extend T::Sig

    sig do
      params(inspector_number: T.nilable(T.any(String, Integer)))
        .returns(T::Array[InspectorInfo])
    end
    def search(inspector_number)
      return [] if inspector_number.blank?

      response = make_api_request(inspector_number)

      if response.code == "200"
        parse_response(JSON.parse(response.body))
      else
        log_error(response)
        []
      end
    end

    sig do
      params(inspector_number: T.nilable(T.any(String, Integer)))
        .returns(VerificationResult)
    end
    def verify(inspector_number)
      results = search(inspector_number)

      inspector = results.find { |r| r[:number]&.to_s == inspector_number.to_s }

      if inspector
        {valid: true, inspector: inspector}
      else
        {valid: false, inspector: nil}
      end
    end

    private

    sig do
      params(inspector_number: T.any(String, Integer))
        .returns(Net::HTTPResponse)
    end
    def make_api_request(inspector_number)
      uri = URI.parse(BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = build_request(uri.path, inspector_number)
      http.request(request)
    end

    sig do
      params(path: String, inspector_number: T.any(String, Integer))
        .returns(Net::HTTP::Post)
    end
    def build_request(path, inspector_number)
      request = Net::HTTP::Post.new(path)
      request["User-Agent"] = USER_AGENT
      content_type = "application/x-www-form-urlencoded; charset=UTF-8"
      request["Content-Type"] = content_type
      request["X-Requested-With"] = "XMLHttpRequest"

      request.body = URI.encode_www_form({
        action: "check_inspector_ajax",
        search: inspector_number.to_s.strip
      })

      request
    end

    sig { params(response: Net::HTTPResponse).void }
    def log_error(response)
      error_msg = "RPII verification failed: #{response.code}"
      Rails.logger.error "#{error_msg} - #{response.body}"
    end

    sig { params(response: T.untyped).returns(T::Array[InspectorInfo]) }
    def parse_response(response)
      suggestions = extract_suggestions(response)
      return [] unless suggestions.is_a?(Array)

      suggestions.map { |item| parse_inspector_item(item) }
    end

    sig { params(response: T.untyped).returns(T.untyped) }
    def extract_suggestions(response)
      if response.is_a?(Hash) && response["suggestions"]
        response["suggestions"]
      elsif response.is_a?(Array)
        response
      else
        []
      end
    end

    sig { params(item: T.untyped).returns(InspectorInfo) }
    def parse_inspector_item(item)
      value = item["value"] || ""
      data = item["data"]

      if /^(.+?)\s*\((.+?)\)$/.match?(value)
        parse_name_qualifications_format(value, data)
      elsif /^(.+?)\s*\((\d+)\)\s*-\s*(.+)$/.match?(value)
        parse_name_number_qualifications_format(value, data)
      else
        {
          raw_value: value,
          number: data,
          id: data
        }
      end
    end

    sig { params(value: String, data: T.untyped).returns(InspectorInfo) }
    def parse_name_qualifications_format(value, data)
      {
        name: T.must($1).strip,
        number: data,  # The data field contains the inspector number
        qualifications: T.must($2).strip,
        id: data,
        raw_value: value
      }
    end

    sig { params(value: String, data: T.untyped).returns(InspectorInfo) }
    def parse_name_number_qualifications_format(value, data)
      {
        name: T.must($1).strip,
        number: $2,
        qualifications: T.must($3).strip,
        id: data,
        raw_value: value
      }
    end
  end
end
