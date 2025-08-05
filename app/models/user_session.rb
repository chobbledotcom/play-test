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
