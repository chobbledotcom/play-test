require "rails_helper"

RSpec.describe NtfyService do
  describe ".notify" do
    it "starts a thread for notification" do
      expect(Thread).to receive(:new)
      NtfyService.notify("Test message")
    end

    it "handles errors gracefully" do
      allow(Thread).to receive(:new).and_yield
      allow(NtfyService).to receive(:send_notification).and_raise(StandardError.new("Test error"))
      expect(Rails.logger).to receive(:error).with("NtfyService error: Test error")

      NtfyService.notify("Test message")
    end
  end
end
