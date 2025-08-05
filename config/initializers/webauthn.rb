WebAuthn.configure do |config|
  config.allowed_origins = [ENV["WEBAUTHN_ORIGIN"] || "http://localhost:3000"]
  config.rp_name = Rails.application.class.module_parent_name
  config.rp_id = ENV["WEBAUTHN_RP_ID"] || "localhost"
end
