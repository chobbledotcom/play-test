require "rails_helper"

RSpec.describe NtfyService do
  describe ".notify" do
    let(:test_message) { "Test notification message" }

    it "accepts a message without raising errors" do
      expect { NtfyService.notify(test_message) }.not_to raise_error
    end

    context "when NTFY_CHANNEL is not configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(nil)
      end

      it "does not attempt HTTP requests" do
        expect(Net::HTTP).not_to receive(:new)
        NtfyService.notify(test_message)
        sleep 0.1 # Give thread time to execute
      end
    end

    context "when NTFY_CHANNEL is configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("test-channel")

        # Stub HTTP to prevent actual network calls
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:request)
      end

      it "attempts to send notification via HTTP" do
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443)
        NtfyService.notify(test_message)
        sleep 0.1 # Give thread time to execute
      end
    end
  end
end
