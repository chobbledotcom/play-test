# typed: false

FactoryBot.define do
  factory :user_session do
    association :user
    session_token { SecureRandom.urlsafe_base64(32) }
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0 (Test Browser)" }
    last_active_at { Time.current }
  end
end
