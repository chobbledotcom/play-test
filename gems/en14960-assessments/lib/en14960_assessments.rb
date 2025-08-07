# typed: false
# frozen_string_literal: true

require_relative "en14960_assessments/version"
require_relative "en14960_assessments/engine"

module En14960Assessments
  class Error < StandardError; end

  # Configuration options for the gem
  mattr_accessor :pdf_cache_enabled
  mattr_accessor :pdf_cache_service
  mattr_accessor :qr_code_base_url

  # Default configuration
  self.pdf_cache_enabled = false
  self.pdf_cache_service = nil
  self.qr_code_base_url = nil

  # Configuration block
  def self.configure
    yield self
  end
end
