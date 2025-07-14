require "rails_helper"

RSpec.describe NtfyService do
  describe ".notify" do
    let(:test_message) { "Test notification message" }

    it "starts a thread for notification" do
      expect(Thread).to receive(:new)
      NtfyService.notify(test_message)
    end

    it "handles errors gracefully" do
      allow(Thread).to receive(:new).and_yield
      error = StandardError.new("Test error")
      allow(NtfyService).to receive(:send_notification).and_raise(error)
      expected_message = "NtfyService error: Test error"
      expect(Rails.logger).to receive(:error).with(expected_message)

      NtfyService.notify(test_message)
    end

    it "releases database connection in ensure block" do
      allow(Thread).to receive(:new).and_yield
      allow(NtfyService).to receive(:send_notification)
      expect(ActiveRecord::Base.connection_pool).to receive(:release_connection)

      NtfyService.notify(test_message)
    end

    context "when NTFY_CHANNEL is not configured" do
      before do
        allow(Thread).to receive(:new).and_yield
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(nil)
        connection_pool = ActiveRecord::Base.connection_pool
        allow(connection_pool).to receive(:release_connection)
      end

      it "does not attempt to send notification" do
        expect(Net::HTTP).not_to receive(:new)
        NtfyService.notify(test_message)
      end
    end

    context "when NTFY_CHANNEL is configured" do
      before do
        allow(Thread).to receive(:new).and_yield
        allow(ENV).to receive(:[]).and_call_original
        test_channel = "test-channel"
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(test_channel)
        connection_pool = ActiveRecord::Base.connection_pool
        allow(connection_pool).to receive(:release_connection)
      end

      it "attempts to send notification" do
        error = StandardError.new("Mocked to prevent real HTTP")
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).and_raise(error)
        expect(Rails.logger).to receive(:error)

        NtfyService.notify(test_message)
      end
    end
  end
end
