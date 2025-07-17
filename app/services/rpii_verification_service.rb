# Service to verify RPII inspector numbers using the official API
require "net/http"
require "uri"
require "json"

class RpiiVerificationService
  BASE_URL = "https://www.playinspectors.com/wp-admin/admin-ajax.php"
  USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

  class << self
    def search(inspector_number)
      return [] if inspector_number.blank?

      uri = URI.parse(BASE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request["User-Agent"] = USER_AGENT
      request["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
      request["X-Requested-With"] = "XMLHttpRequest"

      request.body = URI.encode_www_form({
        action: "check_inspector_ajax",
        search: inspector_number.to_s.strip
      })

      response = http.request(request)

      if response.code == "200"
        parse_response(JSON.parse(response.body))
      else
        Rails.logger.error "RPII verification failed: #{response.code} - #{response.body}"
        []
      end
    end

    def verify(inspector_number)
      results = search(inspector_number)

      inspector = results.find { |r| r[:number]&.to_s == inspector_number.to_s }

      if inspector
        { valid: true, inspector: inspector }
      else
        { valid: false, inspector: nil }
      end
    end

    private

    def parse_response(response)
      if response.is_a?(Hash) && response["suggestions"]
        suggestions = response["suggestions"]
      elsif response.is_a?(Array)
        suggestions = response
      else
        return []
      end

      return [] unless suggestions.is_a?(Array)

      suggestions.map do |item|
        value = item["value"] || ""
        data = item["data"]

        if value =~ /^(.+?)\s*\((.+?)\)$/

          {
            name: $1.strip,
            number: data,  # The data field contains the inspector number
            qualifications: $2.strip,
            id: data,
            raw_value: value
          }
        elsif value =~ /^(.+?)\s*\((\d+)\)\s*-\s*(.+)$/

          {
            name: $1.strip,
            number: $2,
            qualifications: $3.strip,
            id: data,
            raw_value: value
          }
        else
          {
            raw_value: value,
            number: data,
            id: data
          }
        end
      end
    end
  end
end
