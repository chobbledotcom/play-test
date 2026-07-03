# typed: false

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

if Rails.env.production?
  abort("The Rails environment is running in production mode!")
end

require "rspec/rails"
require "factory_bot_rails"
require "capybara/rspec"
require "database_cleaner/active_record"
require "aws-sdk-s3"
require "active_storage/service/s3_service"
require_relative "../lib/i18n_usage_tracker"

Capybara.raise_server_errors = true
Capybara.default_max_wait_time = 10

if ENV["I18N_TRACKING_ENABLED"] == "true"
  I18nUsageTracker.reset!
  I18nUsageTracker.tracking_enabled = true
end

Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# An in-memory database starts empty on every boot, so load the schema
# straight into the live connection (keeping it in the shared cache) rather
# than the file-based maintain_test_schema! dance.
def in_memory_database?
  ActiveRecord::Base.connection_db_config.database.to_s.include?(":memory:")
end

if in_memory_database?
  ActiveRecord::Schema.verbose = false
  load Rails.root.join("db/schema.rb")
else
  begin
    ActiveRecord::Migration.maintain_test_schema!
  rescue ActiveRecord::PendingMigrationError => e
    abort e.to_s.strip
  end
end

# Configure ActiveStorage for test environment
require "active_storage"
ActiveStorage::Current.url_options = {
  host: "play-test.co.uk"
}
RSpec.configure do |config|
  config.before(:each) do
    admin_pattern = "^admin\\d*(_[a-f0-9]+)?@example\\.com$"
    Rails.configuration.admin_emails_pattern = admin_pattern
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
    # Re-establishing the connection for a file-based parallel worker is
    # harmless, but for an in-memory DB it would drop the shared cache (and
    # the schema loaded above) - each worker already has its own in-memory DB.
    if ENV["TEST_ENV_NUMBER"] && !in_memory_database?
      ActiveRecord::Base.establish_connection(
        ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
      )
    end
    # Clean up Active Storage files at the start of test suite
    FileUtils.rm_rf(Rails.root.join("tmp/storage")) if Rails.env.test?
  end

  config.filter_rails_from_backtrace!
end
