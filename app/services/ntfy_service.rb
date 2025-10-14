# typed: false

require "net/http"

class NtfyService
  class << self
    def notify(message, channel: :developer)
      Thread.new do
        send_notifications(message, channel)
      rescue => e
        Rails.logger.error("NtfyService error: #{e.message}")
      ensure
        ActiveRecord::Base.connection_pool.release_connection
      end
    end

    private

    def send_notifications(message, channel)
      channels = determine_channels(channel)
      channels.each { |ch| send_to_channel(message, ch) }
    end

    def determine_channels(channel)
      case channel
      when :developer
        [Rails.configuration.observability.ntfy_channel_developer].compact
      when :admin
        [Rails.configuration.observability.ntfy_channel_admin].compact
      when :both
        channels = [
          Rails.configuration.observability.ntfy_channel_developer,
          Rails.configuration.observability.ntfy_channel_admin
        ]
        channels.compact
      else
        []
      end
    end

    def send_to_channel(message, channel_url)
      return if channel_url.blank?

      uri = URI.parse("https://ntfy.sh/#{channel_url}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request["Title"] = "play-test notification"
      request["Priority"] = "high"
      request["Tags"] = "warning"
      request.body = message

      http.request(request)
    end
  end
end
