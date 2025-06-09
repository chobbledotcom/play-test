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
        expect(mock_request).to receive(:[]=).with("Title", "play-test notification")
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

        expect(mock_request).to receive(:[]=).with("Title", "play-test notification")
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

      it "handles SSL errors" do
        mock_http = instance_double(Net::HTTP)

        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=).and_raise(OpenSSL::SSL::SSLError.new("SSL error"))

        expect(Rails.logger).to receive(:error).with(/NtfyService error:.*SSL error/)

        expect { NtfyService.notify(test_message) }.not_to raise_error
      end

      it "handles StandardError and subclasses" do
        allow(URI).to receive(:parse).and_raise(StandardError.new("Generic error"))
        expect(Rails.logger).to receive(:error).with("NtfyService error: Generic error")

        expect { NtfyService.notify(test_message) }.not_to raise_error
      end
    end

    context "message content variations" do
      let(:channel) { "test-channel" }
      let(:mock_http) { instance_double(Net::HTTP) }
      let(:mock_request) { instance_double(Net::HTTP::Post) }
      let(:mock_response) { instance_double(Net::HTTPResponse) }

      before do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(channel)
        allow(Thread).to receive(:new).and_yield
        allow(ActiveRecord::Base.connection_pool).to receive(:release_connection)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_http).to receive(:request).and_return(mock_response)
      end

      it "handles empty message" do
        expect(mock_request).to receive(:body=).with("")
        NtfyService.notify("")
      end

      it "handles nil message" do
        expect(mock_request).to receive(:body=).with(nil)
        NtfyService.notify(nil)
      end

      it "handles multiline message" do
        multiline_message = "Line 1\nLine 2\nLine 3"
        expect(mock_request).to receive(:body=).with(multiline_message)
        NtfyService.notify(multiline_message)
      end

      it "handles message with special characters" do
        special_message = "Test with émojis 🔥 and special chars: @#$%^&*()"
        expect(mock_request).to receive(:body=).with(special_message)
        NtfyService.notify(special_message)
      end

      it "handles very long message" do
        long_message = "x" * 1000
        expect(mock_request).to receive(:body=).with(long_message)
        NtfyService.notify(long_message)
      end
    end

    context "channel name variations" do
      let(:mock_http) { instance_double(Net::HTTP) }
      let(:mock_request) { instance_double(Net::HTTP::Post) }
      let(:mock_response) { instance_double(Net::HTTPResponse) }

      before do
        allow(Thread).to receive(:new).and_yield
        allow(ActiveRecord::Base.connection_pool).to receive(:release_connection)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_request).to receive(:body=)
        allow(mock_http).to receive(:request).and_return(mock_response)
      end

      it "handles channel with hyphens" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("my-test-channel")
        expect(URI).to receive(:parse).with("https://ntfy.sh/my-test-channel")
        NtfyService.notify(test_message)
      end

      it "handles channel with underscores" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("my_test_channel")
        expect(URI).to receive(:parse).with("https://ntfy.sh/my_test_channel")
        NtfyService.notify(test_message)
      end

      it "handles channel with numbers" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("channel123")
        expect(URI).to receive(:parse).with("https://ntfy.sh/channel123")
        NtfyService.notify(test_message)
      end
    end

    context "threading behavior" do
      let(:channel) { "test-channel" }

      before do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(channel)
      end

      it "executes notification in a separate thread" do
        thread_executed = false
        original_thread_new = Thread.method(:new)

        allow(Thread).to receive(:new) do |&block|
          original_thread_new.call do
            thread_executed = true
            # Mock the HTTP request to avoid actual network call
            mock_http = instance_double(Net::HTTP)
            mock_request = instance_double(Net::HTTP::Post)
            allow(Net::HTTP).to receive(:new).and_return(mock_http)
            allow(mock_http).to receive(:use_ssl=)
            allow(mock_http).to receive(:request)
            allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
            allow(mock_request).to receive(:[]=)
            allow(mock_request).to receive(:body=)
            block.call
          rescue => e
            Rails.logger.error("NtfyService error: #{e.message}")
          ensure
            ActiveRecord::Base.connection_pool.release_connection
          end
        end

        NtfyService.notify(test_message)

        # Give the thread a moment to execute
        sleep(0.01)

        expect(thread_executed).to be true
      end

      it "does not block the main thread" do
        start_time = Time.current

        # Mock a slow HTTP request
        allow(Net::HTTP).to receive(:new) do
          sleep(0.05) # 50ms delay
          mock_http = instance_double(Net::HTTP)
          allow(mock_http).to receive(:use_ssl=)
          allow(mock_http).to receive(:request)
          mock_http
        end
        mock_request = instance_double(Net::HTTP::Post)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_request).to receive(:body=)

        NtfyService.notify(test_message)

        # Should return immediately, not wait for the HTTP request
        elapsed = Time.current - start_time
        expect(elapsed).to be < 0.01 # Should be much faster than the 50ms delay
      end
    end

    context "private method .send_notification" do
      let(:channel) { "test-channel" }

      before do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(channel)
      end

      it "does not send when channel is blank" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("   ")
        expect(URI).not_to receive(:parse)
        NtfyService.send(:send_notification, test_message)
      end

      it "does not send when channel is nil" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return(nil)
        expect(URI).not_to receive(:parse)
        NtfyService.send(:send_notification, test_message)
      end

      it "sends when channel is present" do
        allow(ENV).to receive(:[]).with("NTFY_CHANNEL").and_return("valid-channel")
        mock_uri = instance_double(URI::HTTPS, host: "ntfy.sh", port: 443, path: "/valid-channel")
        expect(URI).to receive(:parse).with("https://ntfy.sh/valid-channel").and_return(mock_uri)
        mock_http = instance_double(Net::HTTP)
        mock_request = instance_double(Net::HTTP::Post)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:request)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_request).to receive(:body=)
        NtfyService.send(:send_notification, test_message)
      end

      it "constructs correct URI path" do
        mock_uri = instance_double(URI::HTTPS, host: "ntfy.sh", port: 443, path: "/#{channel}")
        expect(URI).to receive(:parse).with("https://ntfy.sh/#{channel}").and_return(mock_uri)

        mock_http = instance_double(Net::HTTP)
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).and_return(mock_http)
        expect(mock_http).to receive(:use_ssl=).with(true)

        mock_request = instance_double(Net::HTTP::Post)
        expect(Net::HTTP::Post).to receive(:new).with("/#{channel}").and_return(mock_request)
        expect(mock_request).to receive(:[]=).exactly(3).times
        expect(mock_request).to receive(:body=).with(test_message)
        expect(mock_http).to receive(:request).with(mock_request)

        NtfyService.send(:send_notification, test_message)
      end
    end
  end
end
