namespace :ntfy do
  desc "Send a test notification to ntfy.sh"
  task test: :environment do
    channel = ENV["CHANNEL"]&.to_sym || :developer
    timestamp = Time.zone.now
    message = "Test notification from PatLog at #{timestamp}"

    puts "Sending test notification to channel: #{channel}"
    puts "Message: #{message}"

    # Since notify runs in a thread, we need to call the private methods directly for testing
    channels = NtfyService.send(:determine_channels, channel)

    if channels.empty?
      puts "No channels configured for :#{channel}"
      exit 1
    end

    puts "Sending to channels: #{channels.join(", ")}"

    channels.each do |ch|
      response = NtfyService.send(:send_to_channel, message, ch)
      if response.is_a?(Net::HTTPSuccess)
        code = response.code
        puts "Notification sent successfully to #{ch}! Response code: #{code}"
      else
        code = response.code
        msg = response.message
        puts "Failed to send to #{ch}. Response: #{code} #{msg}"
      end
    end
  end
end
