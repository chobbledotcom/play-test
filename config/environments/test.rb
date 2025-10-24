# typed: false
# frozen_string_literal: true

require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = true # ENV["CI"].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.headers = {"Cache-Control" => "public, max-age=#{1.hour.to_i}"}

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  config.assets.debug = false

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Override the default Active Storage service for test environment
  config.active_storage.service = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # Use test adapter for Active Job in tests
  config.active_job.queue_adapter = :test

  # Default app config for tests
  config.app = AppConfig.new(
    has_assessments: true,
    base_url: config.app.base_url,
    name: config.app.name
  )

  # Admin email pattern for tests (matches factory :admin trait)
  config.users = UsersConfig.new(
    simple_activation: config.users.simple_activation,
    admin_emails_pattern: "^admin.*@example\\.com$"
  )

  # Units config for tests (disable badges)
  config.units = UnitsConfig.new(
    badges_enabled: false,
    reports_unbranded: config.units.reports_unbranded,
    pdf_filename_prefix: config.units.pdf_filename_prefix
  )
end
