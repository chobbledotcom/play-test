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

    # Storage Configuration
    config.use_s3_storage = ENV["USE_S3_STORAGE"] == "true"
    config.active_storage.service = config.use_s3_storage ? :s3_host : :local
    config.active_storage.service_urls_expire_in = 1.day
    config.s3_endpoint = ENV["S3_ENDPOINT"]
    config.s3_bucket = ENV["S3_BUCKET"]
    config.s3_region = ENV["S3_REGION"]

    # PDF Generation Configuration
    config.pdf_cache_enabled = ENV["PDF_CACHE_FROM"].present?
    pdf_cache_date = ENV["PDF_CACHE_FROM"]
    config.pdf_cache_from = pdf_cache_date.present? ? Date.parse(pdf_cache_date) : nil
    config.redirect_to_s3_pdfs = ENV["REDIRECT_TO_S3_PDFS"] == "true"
    config.pdf_logo = ENV["PDF_LOGO"]

    # Theme and UI Configuration
    config.forced_theme = ENV["THEME"] # If set, overrides user preference
    config.logo_path = ENV.fetch("LOGO_PATH", "logo.svg")
    config.logo_alt = ENV.fetch("LOGO_ALT", "play-test logo")
    config.left_logo_path = ENV["LEFT_LOGO_PATH"]
    config.left_logo_alt = ENV.fetch("LEFT_LOGO_ALT", "Logo")
    config.right_logo_path = ENV["RIGHT_LOGO_PATH"]
    config.right_logo_alt = ENV.fetch("RIGHT_LOGO_ALT", "Logo")

    # Features and Functionality
    config.has_assessments = ENV["HAS_ASSESSMENTS"] == "true"
    config.simple_user_activation = ENV["SIMPLE_USER_ACTIVATION"] == "true"
    config.admin_emails_pattern = ENV["ADMIN_EMAILS_PATTERN"]
    config.base_url = ENV.fetch("BASE_URL", "http://localhost:3000")
    config.app_name = ENV.fetch("APP_NAME", "Play-Test")

    # Notification Configuration
    config.ntfy_channel_developer = ENV["NTFY_CHANNEL_DEVELOPER"]
    config.ntfy_channel_admin = ENV["NTFY_CHANNEL_ADMIN"]

    # Unit Configuration
    config.unit_badges_enabled = ENV["UNIT_BADGES"] == "true"
    config.unit_reports_unbranded = ENV["UNIT_REPORTS_UNBRANDED"] == "true"

    # I18n Configuration
    default_overrides = Rails.root.join("config/site_overrides.yml").to_s
    config.i18n_overrides_path = ENV.fetch("I18N_OVERRIDES_PATH", default_overrides)

    # Add site-specific i18n overrides
    config.before_initialize do
      override_path = config.i18n_overrides_path
      config.i18n.load_path << override_path if File.exist?(override_path)
    end

    # Use the application to handle all exceptions (including 404s)
    config.exceptions_app = routes
  end
end
