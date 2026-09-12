# typed: false

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

unless Rails.env.test?
  abort("Refusing to load the test schema outside the test environment.")
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

pid = Process.pid
expected_database = if ENV["IN_MEMORY_DB"] == "true"
  "file::memory:?cache=shared"
else
  "tmp/test-#{pid}.sqlite3"
end
database_config = ActiveRecord::Base.connection_db_config
unless database_config.adapter == "sqlite3" &&
    database_config.database == expected_database
  abort("Refusing to load the test schema outside the isolated test database.")
end

# Each process owns its database, so no migration or parallel preparation
# is needed. Mutant selects its fork-isolated memory database before Rails boots.
ActiveRecord::Schema.verbose = false
load Rails.root.join("db/schema.rb")

# Configure ActiveStorage for test environment
require "active_storage"
ActiveStorage::Current.url_options = {
  host: "play-test.co.uk"
}
RSpec.configure do |config|
  config.before(:each) do |example|
    admin_pattern = "^admin\\d*(_[a-f0-9]+)?@example\\.com$"
    Rails.configuration.admin_emails_pattern = admin_pattern
    uses_threads = example.metadata[:js] || example.metadata[:concurrent]
    DatabaseCleaner.strategy = uses_threads ? :truncation : :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  # Capybara must finish pending requests before their tables are cleaned.
  config.append_after(:each) do
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
    # Clean up Active Storage files at the start of test suite
    FileUtils.rm_rf(Rails.root.join("tmp/storage")) if Rails.env.test?
  end

  config.after(:suite) do
    current_pid = Process.pid
    database = "tmp/test-#{current_pid}.sqlite3"
    if ActiveRecord::Base.connection_db_config.database == database
      ActiveRecord::Base.connection_pool.disconnect!
      database = Rails.root.join(database).to_s
      FileUtils.rm_f([database, "#{database}-shm", "#{database}-wal"])
    end
  end

  config.filter_rails_from_backtrace!
end
