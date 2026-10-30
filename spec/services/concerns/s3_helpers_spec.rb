# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe S3Helpers do
  let(:service) do
    Class.new do
      include S3Helpers
    end.new
  end

  describe "#ensure_s3_enabled" do
    it "raises when S3 storage is not enabled" do
      allow(Rails.configuration.s3).to receive(:enabled).and_return(false)
      expect { service.send(:ensure_s3_enabled) }
        .to raise_error("S3 storage is not enabled")
    end

    it "does not raise when S3 storage is enabled" do
      allow(Rails.configuration.s3).to receive(:enabled).and_return(true)
      expect { service.send(:ensure_s3_enabled) }.not_to raise_error
    end
  end

  describe "#validate_s3_config" do
    around do |example|
      original = ENV.to_h.slice("S3_ENDPOINT", "S3_ACCESS_KEY_ID", "S3_SECRET_ACCESS_KEY", "S3_BUCKET")
      example.run
    ensure
      original.each { |key, value| ENV[key] = value }
      %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET].each do |key|
        ENV.delete(key) unless original.key?(key)
      end
    end

    it "raises when required config is missing" do
      %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET].each { |k| ENV.delete(k) }
      expect { service.send(:validate_s3_config) }
        .to raise_error(/Missing S3 config/)
    end

    it "does not raise when all required config is present" do
      %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET].each do |key|
        ENV[key] = "set"
      end
      expect { service.send(:validate_s3_config) }.not_to raise_error
    end
  end

  describe "#get_s3_service" do
    it "returns the Active Storage blob service" do
      expect(service.send(:get_s3_service))
        .to eq(ActiveStorage::Blob.service)
    end
  end
end
