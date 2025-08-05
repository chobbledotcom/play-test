# frozen_string_literal: true

# Set default values for environment variables if not already set
# The 00_ prefix ensures this runs before other initializers

ENV["APP_NAME"] ||= "Play-Test"
ENV["BASE_URL"] ||= "http://localhost:3000"
