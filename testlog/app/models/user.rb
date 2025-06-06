class User < ApplicationRecord
  include CustomIdGenerator

  has_secure_password
  has_many :inspections, dependent: :destroy
  has_many :units, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, presence: true, length: {minimum: 6}, if: :password_digest_changed?
  validates :inspection_limit, numericality: {only_integer: true, greater_than_or_equal_to: -1}
  validates :time_display, inclusion: {in: %w[date time]}

  before_create :set_default_inspection_limit
  before_create :set_default_time_display
  before_save :downcase_email

  def can_create_inspection?
    inspection_limit == -1 || inspections.count < inspection_limit
  end

  def admin?
    admin_pattern = ENV["ADMIN_EMAILS_PATTERN"]
    return false if admin_pattern.blank?

    begin
      regex = Regexp.new(admin_pattern)
      regex.match?(email)
    rescue RegexpError
      false
    end
  end

  private

  def downcase_email
    self.email = email.downcase
  end

  def set_default_inspection_limit
    env_limit = ENV["LIMIT_INSPECTIONS"]
    self.inspection_limit = env_limit.present? ? env_limit.to_i : 10
  end

  def set_default_time_display
    self.time_display ||= "date"
  end
end
