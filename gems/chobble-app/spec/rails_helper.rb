# frozen_string_literal: true

require "spec_helper"

# Load the dummy app or the host Rails application
ENV["RAILS_ENV"] ||= "test"

# Require the gem
require "chobble_app"

# Load Rails testing environment
require "rspec/rails"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end