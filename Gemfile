# typed: false
# frozen_string_literal: true

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.0"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# SCSS/Sass support for Rails [https://github.com/rails/sass-rails]
gem "sass-rails", "~> 6.0"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 1.4"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Using in-memory queue for background processing
gem "solid_queue"

# WebAuthn for passkey support
gem "webauthn", "~> 3.4"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

gem "chobble-forms", "~> 0.9.0"
gem "en14960"

# Sorbet runtime (needed in all environments and
# pinned for nixpkgs)
gem "sorbet-runtime", "0.6.12753"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # N+1 query detection
  gem "prosopite"
  gem "pg_query"
end

group :development do
  # Ruby code formatter and linter
  gem "standard", require: false
  gem "standard-rails", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # ERB linter with better-html support
  gem "erb_lint", require: false
  gem "better_html", require: false

  # Sorbet type checker
  gem "sorbet", require: false
  gem "tapioca", require: false

  # Rubocop extension for Sorbet
  gem "rubocop-sorbet", require: false
end

group :test do
  # Testing framework
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "capybara"
  gem "cuprite"

  # Test utilities
  gem "pdf-inspector", require: false
  gem "parallel_tests"
  gem "database_cleaner-active_record"

  # RSpec matchers for Sorbet
  gem "rspec-sorbet"
end

# PDF generation
gem "prawn"
gem "prawn-table"

# Passwords
gem "bcrypt"

gem "importmap-rails", "~> 2.1"

# Image processing
gem "image_processing", "~> 1.12"

# Pin ruby-vips for nixpkgs compatibility
# Note: Requires libvips to be installed on the system
gem "ruby-vips", "= 2.2.3", require: false

# QR code generation
gem "rqrcode"

# Environment variables
gem "dotenv-rails"

# CSV support for Ruby 3.4+
gem "csv"

# CORS support for federation
gem "rack-cors"

# JSON serialization
gem "blueprinter"

gem "rails-controller-testing", "~> 1.0", groups: %i[development test]

gem "turbo-rails", "~> 2.0"

# Error tracking with BugSink (Sentry-compatible)
gem "sentry-ruby"
gem "sentry-rails"

# S3-compatible storage
gem "aws-sdk-s3", require: false

# SQLite replication to S3
gem "litestream"

# Mission Control for managing background jobs
gem "mission_control-jobs", "~> 1.0"

# Production-only gems
group :production do
  # Cron job management
  gem "whenever", require: false
end

# Pinned for nixpkgs
gem "psych", "= 5.2.3"
gem "openssl", "3.3.2"

# CI-only groups - excluded in development setup
group :ci_annotations do
  # Annotate models with schema info
  gem "annotaterb", require: false

  # License compliance
  gem "licensed", "~> 5.0"
end

group :ci_coverage, :test do
  # Code coverage
  gem "simplecov", require: false
  gem "simplecov-cobertura", require: false

  # JUnit formatter for RSpec (for CI integration)
  gem "rspec_junit_formatter"
end
