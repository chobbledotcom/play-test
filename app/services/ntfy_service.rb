# typed: strict

require "net/http"

class NtfyService
  extend T::Sig

  class << self
    extend T::Sig

    sig { params(message: String, channel: Symbol).returns(Thread) }
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

    sig { params(message: String, channel: Symbol).void }
    def send_notifications(message, channel)
      channels = determine_channels(channel)
      channels.each { |ch| send_to_channel(message, ch) }
    end

    sig { params(channel: Symbol).returns(T::Array[String]) }
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

    sig { params(message: String, channel_url: String).returns(T.nilable(Net::HTTPResponse)) }
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
