# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SentryAvailabilityService, type: :service do
  describe ".available?" do
    let(:dsn) { "https://63b4c907bb8b48f5a4d888dd42d1978c@bugsink.example.com/1" }

    it "returns true when the DSN endpoint accepts a connection" do
      socket = instance_double(TCPSocket, close: nil)
      allow(Socket).to receive(:tcp)
        .with("bugsink.example.com", 443, connect_timeout: 2).and_return(socket)

      expect(described_class.available?(dsn)).to be(true)
      expect(socket).to have_received(:close)
    end

    it "returns false when the connection is refused" do
      allow(Socket).to receive(:tcp).and_raise(Errno::ECONNREFUSED)

      expect(described_class.available?(dsn)).to be(false)
    end

    it "returns false when the DSN host cannot be resolved" do
      allow(Socket).to receive(:tcp).and_raise(SocketError)

      expect(described_class.available?(dsn)).to be(false)
    end

    it "returns false when the probe exceeds the timeout" do
      socket = instance_double(TCPSocket, close: nil)
      allow(Socket).to receive(:tcp) do
        sleep 1
        socket
      end
      stub_const("SentryAvailabilityService::PROBE_TIMEOUT_SECONDS", 0.01)

      expect(described_class.available?(dsn)).to be(false)
    end
  end
end
