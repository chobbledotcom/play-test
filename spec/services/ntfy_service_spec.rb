# typed: false

require "rails_helper"

RSpec.describe NtfyService do
  describe ".notify" do
    let(:test_message) { "Test notification message" }
    let(:http_double) { instance_double(Net::HTTP) }

    define_method(:set_ntfy_channels) do |developer: nil, admin: nil|
      config = ObservabilityConfig.new(
        ntfy_channel_developer: developer,
        ntfy_channel_admin: admin,
        sentry_dsn: nil,
        git_commit: nil
      )
      Rails.configuration.observability = config
    end

    before do
      allow(Net::HTTP).to receive(:new).and_return(http_double)
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:request)
    end

    it "accepts a message without raising errors" do
      expect { NtfyService.notify(test_message) }.not_to raise_error
    end

    context "when no channels are configured" do
      before do
        set_ntfy_channels
      end

      it "does not attempt HTTP requests" do
        expect(Net::HTTP).not_to receive(:new)
        NtfyService.notify(test_message)
        sleep 0.1 # Give thread time to execute
      end
    end

    context "when developer channel is configured" do
      before do
        set_ntfy_channels(developer: "dev-channel")
      end

      after do
        set_ntfy_channels
      end

      it "sends to developer channel by default" do
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).once
        NtfyService.notify(test_message)
        sleep 0.1 # Give thread time to execute
      end

      it "sends to developer channel when explicitly specified" do
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).once
        NtfyService.notify(test_message, channel: :developer)
        sleep 0.1 # Give thread time to execute
      end
    end

    context "when admin channel is configured" do
      before do
        set_ntfy_channels(admin: "admin-channel")
      end

      after do
        set_ntfy_channels
      end

      it "sends to admin channel when specified" do
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).once
        NtfyService.notify(test_message, channel: :admin)
        sleep 0.1 # Give thread time to execute
      end

      it "does not send to admin channel by default" do
        expect(Net::HTTP).not_to receive(:new)
        NtfyService.notify(test_message)
        sleep 0.1 # Give thread time to execute
      end
    end

    context "when both channels are configured" do
      before do
        set_ntfy_channels(developer: "dev-channel", admin: "admin-channel")
      end

      after do
        set_ntfy_channels
      end

      it "sends to both channels when :both is specified" do
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).twice
        NtfyService.notify(test_message, channel: :both)
        sleep 0.1 # Give thread time to execute
      end

      it "sends only to developer channel by default" do
        expect(Net::HTTP).to receive(:new).with("ntfy.sh", 443).once
        NtfyService.notify(test_message)
        sleep 0.1 # Give thread time to execute
      end
    end
  end
end
