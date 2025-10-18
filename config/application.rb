# typed: false
# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Load dotenv manually since it might not be loaded yet
require "dotenv/load"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load typed configuration classes
require_relative "../app/config/app_config"
require_relative "../app/config/litestream_config"
require_relative "../app/config/observability_config"
require_relative "../app/config/pdf_config"
require_relative "../app/config/s3_config"
require_relative "../app/config/theme_config"
require_relative "../app/config/units_config"
require_relative "../app/config/users_config"

module PlayTest
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks rubocop])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Configure Sass/SCSS compilation to use expanded style
    config.sass.preferred_syntax = :scss
    config.sass.style = :expanded

    # Preserve full timezone rather than offset in Rails 8.1+
    config.active_support.to_time_preserves_timezone = :zone

    # === Environment Variable Configuration ===
    # Centralized configuration for all application-level ENV variables
    # No rescues - if a value exists, we assume it's in the correct format

    # Storage Configuration (typed)
    config.s3 = S3Config.from_env(ENV.to_h)
    service = config.s3.enabled ? :s3_host : :local
    config.active_storage.service = service
    config.active_storage.service_urls_expire_in = 1.day

    # PDF Generation Configuration (typed)
    config.pdf = PdfConfig.from_env(ENV.to_h)

    # Theme and UI Configuration (typed)
    config.theme = ThemeConfig.from_env(ENV.to_h)

    # Application Configuration (typed)
    config.app = AppConfig.from_env(ENV.to_h)

    # Users / Auth Configuration (typed)
    config.users = UsersConfig.from_env(ENV.to_h)

    # Observability Configuration (typed)
    config.observability = ObservabilityConfig.from_env(ENV.to_h)

    # Unit Configuration (typed)
    config.units = UnitsConfig.from_env(ENV.to_h)

    # Litestream Configuration (typed)
    # Note: stored as config.litestream_config (not config.litestream)
    # because litestream gem uses config.litestream for its own settings
    config.litestream_config = LitestreamConfig.from_env(ENV.to_h)

    # I18n Configuration
    default_overrides = Rails.root.join("config/site_overrides.yml").to_s
    overrides_env_key = "I18N_OVERRIDES_PATH"
    config.i18n_overrides_path = ENV.fetch(overrides_env_key, default_overrides)

    # Add site-specific i18n overrides
    config.before_initialize do
      override_path = config.i18n_overrides_path
      config.i18n.load_path << override_path if File.exist?(override_path)
    end

    # Use the application to handle all exceptions (including 404s)
    config.exceptions_app = routes
  end
end
