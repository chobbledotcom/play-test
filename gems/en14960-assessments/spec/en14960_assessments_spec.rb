# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe En14960Assessments do
  it "has a version number" do
    expect(En14960Assessments::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "allows configuration" do
      En14960Assessments.configure do |config|
        config.pdf_cache_enabled = true
        config.qr_code_base_url = "https://example.com"
      end

      expect(En14960Assessments.pdf_cache_enabled).to be true
      expect(En14960Assessments.qr_code_base_url).to eq("https://example.com")
    end
  end
end
