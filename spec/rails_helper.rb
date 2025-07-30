require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"
require "capybara/rspec"
require "database_cleaner/active_record"
require_relative "../lib/i18n_usage_tracker"

Capybara.raise_server_errors = true
Capybara.default_max_wait_time = 10

if ENV["I18N_TRACKING_ENABLED"] == "true"
  I18nUsageTracker.reset!
  I18nUsageTracker.tracking_enabled = true
end

Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.before(:each) do
    ENV["ADMIN_EMAILS_PATTERN"] = "^admin\\d*(_[a-f0-9]+)?@example\\.com$"
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include FactoryBot::Syntax::Methods
  config.include Capybara::RSpecMatchers, type: :view
  config.include Capybara::DSL, type: :feature
  config.include Capybara::DSL, type: :request
  config.include FormHelpers, type: :feature
  # config.include ChobbleForms::Helpers, type: :view

  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    if ENV["TEST_ENV_NUMBER"]
      ActiveRecord::Base.establish_connection(
        ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
      )
    end
    # Clean up Active Storage files at the start of test suite
    FileUtils.rm_rf(Rails.root.join("tmp/storage")) if Rails.env.test?
  end

  config.filter_rails_from_backtrace!
end
