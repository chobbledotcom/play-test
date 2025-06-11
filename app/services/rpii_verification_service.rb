# Service to verify RPII inspector numbers using the official API
require "net/http"
require "uri"
require "json"

class RpiiVerificationService
  BASE_URL = "https://www.playinspectors.com/wp-admin/admin-ajax.php"
  USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  
  class << self
    # Search for an inspector by their membership number
    # Returns an array of matching inspectors with their details
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
      
      begin
        response = http.request(request)
        
        if response.code == "200"
          parse_response(JSON.parse(response.body))
        else
          Rails.logger.error "RPII verification failed: #{response.code} - #{response.body}"
          []
        end
      rescue => e
        Rails.logger.error "RPII verification error: #{e.message}"
        []
      end
    end
    
    # Verify if a specific inspector number is valid
    # Returns true/false and optionally the inspector details
    def verify(inspector_number)
      results = search(inspector_number)
      
      # Look for exact match
      inspector = results.find { |r| r[:number]&.to_s == inspector_number.to_s }
      
      if inspector
        { valid: true, inspector: inspector }
      else
        { valid: false, inspector: nil }
      end
    end
    
    private
    
    def parse_response(response)
      # The API returns an array of suggestions
      # Each suggestion has 'value' (display text) and 'data' (inspector ID)
      return [] unless response.is_a?(Array)
      
      response.map do |item|
        # Extract inspector details from the value field
        # Format appears to be "Name (Number) - Qualifications"
        value = item["value"] || ""
        data = item["data"]
        
        # Parse the value to extract components
        if value =~ /^(.+?)\s*\((\d+)\)\s*-\s*(.+)$/
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
            id: data
          }
        end
      end
    end
  end
end