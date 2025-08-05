WebAuthn.configure do |config|
  # Use BASE_URL from environment
  base_url = ENV["BASE_URL"]

  config.allowed_origins = [base_url]

  # Use APP_NAME from environment
  config.rp_name = ENV["APP_NAME"]

  # Extract domain from BASE_URL
  config.rp_id = URI.parse(base_url).host
end
