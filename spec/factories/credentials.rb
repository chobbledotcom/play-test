# == Schema Information
#
# Table name: credentials
#
#  id          :integer          not null, primary key
#  nickname    :string           not null
#  public_key  :string           not null
#  sign_count  :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  external_id :string           not null
#  user_id     :string(12)       not null
#
# Indexes
#
#  index_credentials_on_external_id  (external_id) UNIQUE
#  index_credentials_on_user_id      (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
FactoryBot.define do
  factory :credential do
    association :user
    external_id { SecureRandom.base64(16) }
    public_key { SecureRandom.base64(32) }
    nickname { "Test Passkey" }
    sign_count { 0 }
  end
end
