require "rails_helper"

RSpec.describe NtfyService do
  describe ".notify" do
    let(:test_message) { "Test notification message" }

    before do
      # Ensure clean environment for each test
      allow(ENV).to receive(:[]).and_call_original
    end

    it "starts a thread for notification" do
      expect(Thread).to receive(:new)
      NtfyService.notify(test_message)
    end

    it "handles errors gracefully" do
      allow(Thread).to receive(:new).and_yield
      allow(NtfyService).to receive(:send_notification).and_raise(StandardError.new("Test error"))
      expect(Rails.logger).to receive(:error).with("NtfyService error: Test error")

      NtfyService.notify(test_message)
    end

    it "releases database connection in ensure block" do
      allow(Thread).to receive(:new).and_yield
      allow(NtfyService).to receive(:send_notification)
      expect(ActiveRecord::Base.connection_pool).to receive(:release_connection)

      NtfyService.notify(test_message)
    end

    context "when NTFY_CHANNEL is configured" do
      let(:channel) { "test-channel-123" }
      let(:mock_http) { instance_double(Net::HTTP) }
      let(:mock_request) { instance_double(Net::HTTP::Post) }
      let(:mock_response) { instance_double(Net::HTTPResponse) }

      before do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(channel)
        allow(Thread).to receive(:new).and_yield
        allow(ActiveRecord::Base.connection_pool).to receive(:release_connection)
      end

      it "sends notification to correct ntfy.sh URL" do
        expect(URI).to receive(:parse).with("https://ntfy.sh/#{channel}").and_call_original
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).and_return(mock_http)
        expect(mock_http).to receive(:use_ssl=).with(true)
        expect(Net::HTTP::Post).to receive(:new).with("/#{channel}").and_return(mock_request)

        # Expect headers to be set
        expect(mock_request).to receive(:[]=).with("Title", "patlog notification")
        expect(mock_request).to receive(:[]=).with("Priority", "high")
        expect(mock_request).to receive(:[]=).with("Tags", "warning")
        expect(mock_request).to receive(:body=).with(test_message)

        expect(mock_http).to receive(:request).with(mock_request).and_return(mock_response)

        NtfyService.notify(test_message)
      end

      it "sets correct HTTP headers" do
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect(mock_request).to receive(:[]=).with("Title", "patlog notification")
        expect(mock_request).to receive(:[]=).with("Priority", "high")
        expect(mock_request).to receive(:[]=).with("Tags", "warning")
        expect(mock_request).to receive(:body=).with(test_message)

        NtfyService.notify(test_message)
      end

      it "uses SSL for HTTPS connection" do
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_request).to receive(:body=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect(mock_http).to receive(:use_ssl=).with(true)

        NtfyService.notify(test_message)
      end
    end

    context "when NTFY_CHANNEL is not configured" do
      before do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(nil)
        allow(Thread).to receive(:new).and_yield
        allow(ActiveRecord::Base.connection_pool).to receive(:release_connection)
      end

      it "does not send notification when channel is nil" do
        expect(Net::HTTP).not_to receive(:new)
        expect(URI).not_to receive(:parse)

        NtfyService.notify(test_message)
      end

      it "does not send notification when channel is empty string" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("")

        expect(Net::HTTP).not_to receive(:new)
        expect(URI).not_to receive(:parse)

        NtfyService.notify(test_message)
      end

      it "does not send notification when channel is whitespace" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("   ")

        expect(Net::HTTP).not_to receive(:new)
        expect(URI).not_to receive(:parse)

        NtfyService.notify(test_message)
      end
    end

    context "error handling" do
      let(:channel) { "test-channel" }

      before do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(channel)
        allow(Thread).to receive(:new).and_yield
        allow(ActiveRecord::Base.connection_pool).to receive(:release_connection)
      end

      it "handles URI parsing errors" do
        allow(URI).to receive(:parse).and_raise(URI::InvalidURIError.new("Invalid URI"))
        expect(Rails.logger).to receive(:error).with("NtfyService error: Invalid URI")

        expect { NtfyService.notify(test_message) }.not_to raise_error
      end

      it "handles HTTP connection errors" do
        allow(Net::HTTP).to receive(:new).and_raise(Net::OpenTimeout.new("Connection timeout"))
        expect(Rails.logger).to receive(:error).with(/NtfyService error:.*Connection timeout/)

        expect { NtfyService.notify(test_message) }.not_to raise_error
      end

      it "handles HTTP request errors" do
        mock_http = instance_double(Net::HTTP)
        mock_request = instance_double(Net::HTTP::Post)

        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_request).to receive(:body=)
        allow(mock_http).to receive(:request).and_raise(Net::ReadTimeout.new("Read timeout"))

        expect(Rails.logger).to receive(:error).with(/NtfyService error:.*Read timeout/)

        expect { NtfyService.notify(test_message) }.not_to raise_error
      end
    end
  end
end
