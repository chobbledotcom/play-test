source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 1.4"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Using in-memory queue for background processing

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "capybara"
  gem "cuprite"
  gem "simplecov", require: false
  gem "pdf-inspector", require: false
  gem "parallel_tests"
  gem "database_cleaner-active_record"

  # Ruby code formatter and linter
  gem "standard", require: false
  gem "standard-rails"
end

# PDF generation
gem "prawn"
gem "prawn-table"

# Passwords
gem "bcrypt"

gem "importmap-rails", "~> 2.1"

# Image processing
gem "image_processing", "~> 1.12"

# QR code generation
gem "rqrcode"

# Environment variables
gem "dotenv-rails"

# CSV support for Ruby 3.4+
gem "csv"

# CORS support for federation
gem "rack-cors"

gem "rails-controller-testing", "~> 1.0", groups: [:development, :test]

gem "turbo-rails", "~> 2.0"

# EN 14960:2019 safety standards calculators
gem "en14960", "~> 0.1.6"
