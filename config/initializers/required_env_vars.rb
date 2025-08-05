# Check for required environment variables on boot
REQUIRED_ENV_VARS = %w[BASE_URL APP_NAME].freeze unless defined?(REQUIRED_ENV_VARS)

missing_vars = REQUIRED_ENV_VARS.select { |var| ENV[var].blank? }

if missing_vars.any?
  raise "Missing required environment variables: #{missing_vars.join(", ")}. " \
        "Please set these in your environment."
end
