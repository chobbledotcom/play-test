# typed: false

WebAuthn.configure do |config|
  # Use configuration values
  base_url = Rails.configuration.app.base_url
  config.allowed_origins = [base_url]
  config.rp_name = Rails.configuration.app.name
  config.rp_id = URI.parse(base_url).host
end
