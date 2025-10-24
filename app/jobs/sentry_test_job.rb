# typed: false
# frozen_string_literal: true

class SentryTestJob < ApplicationJob
  queue_as :default

  def perform(error_type = nil)
    service = SentryTestService.new

    if error_type
      # Test a specific error type
      service.test_error_type(error_type.to_sym)
      Rails.logger.info "SentryTestJob: Sent #{error_type} error to Sentry"
    else
      # Run all tests
      result = service.perform

      Rails.logger.info "SentryTestJob completed:"
      result[:results].each do |test_result|
        status_emoji = (test_result[:status] == "success") ? "✅" : "❌"
        Rails.logger.info "  #{status_emoji} #{test_result[:test]}: #{test_result[:message]}"
      end

      Rails.logger.info "Sentry configuration:"
      Rails.logger.info "  DSN: #{result[:configuration][:dsn_configured] ?
        "Configured" :
        "Not configured"}"
      Rails.logger.info "  Environment: #{result[:configuration][:environment]}"
      Rails.logger.info "  Enabled environments: #{result[:configuration][:enabled_environments].join(", ")}"
    end
  end
end
