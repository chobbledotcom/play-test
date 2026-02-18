# typed: false

# == Schema Information
#
# Table name: user_sessions
#
#  id             :integer          not null, primary key
#  ip_address     :string
#  last_active_at :datetime         not null
#  session_token  :string           not null
#  user_agent     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :string(12)       not null
#
# Indexes
#
#  index_user_sessions_on_session_token               (session_token) UNIQUE
#  index_user_sessions_on_user_id                     (user_id)
#  index_user_sessions_on_user_id_and_last_active_at  (user_id,last_active_at)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
FactoryBot.define do
  factory :user_session do
    association :user
    session_token { SecureRandom.urlsafe_base64(32) }
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0 (Test Browser)" }
    last_active_at { Time.current }
  end
end
