require "net/http"

class NtfyService
  class << self
    def notify(message)
      Thread.new do
        send_notification(message)
      rescue => e
        Rails.logger.error("NtfyService error: #{e.message}")
      ensure
        ActiveRecord::Base.connection_pool.release_connection
      end
    end

    private

    def send_notification(message)
      channel = ENV["NTFY_CHANNEL"]
      return unless channel.present?

      uri = URI.parse("https://ntfy.sh/#{channel}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request["Title"] = "patlog notification"
      request["Priority"] = "high"
      request["Tags"] = "warning"
      request.body = message

      http.request(request)
    end
  end
end
