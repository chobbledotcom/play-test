# typed: false
# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    ApplicationController::RATE_LIMIT_STORE.clear
  end
end
