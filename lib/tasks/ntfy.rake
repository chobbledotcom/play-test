namespace :ntfy do
  desc "Send a test notification to ntfy.sh"
  task test: :environment do
    message = "Test notification from PatLog at #{Time.now}"
    puts "Sending test notification to ntfy.sh channel: #{ENV["NTFY_CHANNEL"]}"
    puts "Message: #{message}"

    response = NtfyService.send(:send_notification, message)
    if response.is_a?(Net::HTTPSuccess)
      puts "Notification sent successfully! Response code: #{response.code}"
    else
      puts "Failed to send notification. Response: #{response.code} #{response.message}"
    end
  end
end
