FactoryBot.define do
  factory :credential do
    association :user
    external_id { SecureRandom.base64(16) }
    public_key { SecureRandom.base64(32) }
    nickname { "Test Passkey" }
    sign_count { 0 }
  end
end
