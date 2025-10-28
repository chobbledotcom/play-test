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

class UserSession < ApplicationRecord
  belongs_to :user

  validates :session_token, presence: true, uniqueness: true
  validates :last_active_at, presence: true

  before_validation :generate_session_token, on: :create

  scope :active, -> { where("last_active_at > ?", 30.days.ago) }
  scope :recent, -> { order(last_active_at: :desc) }

  def active? = last_active_at > 30.days.ago

  def touch_last_active
    update_column(:last_active_at, Time.current)
  end

  private

  def generate_session_token
    self.session_token ||= SecureRandom.urlsafe_base64(32)
  end
end
