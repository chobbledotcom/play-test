ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"
require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "rspec/rails"

# Load the gem
require "chobble-forms"

# Create a minimal Rails application for testing
module ChobbleFormsTest
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = "test-secret-key-base"

    # Minimal middleware stack
    config.middleware.delete ActionDispatch::Cookies
    config.middleware.delete ActionDispatch::Session::CookieStore
    config.middleware.delete ActionDispatch::Flash

    # Add a simple rack app
    config.middleware.use Rack::Runtime
  end
end

# Initialize the Rails application
Rails.application.initialize!

# Create a test controller for view specs
class ApplicationController < ActionController::Base
end

# Include I18n test helpers
I18n.load_path += Dir[File.expand_path("../fixtures/locales/*.yml", __FILE__)]
I18n.default_locale = :en
I18n.backend.reload!

require "spec_helper"

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include ChobbleForms::Helpers, type: :view

  # Clear I18n backend between tests
  config.before(:each) do
    I18n.backend.reload!
  end
end
