class User < ApplicationRecord
  include CustomIdGenerator

  has_secure_password
  has_many :inspections, dependent: :destroy
  has_many :units, dependent: :destroy
  belongs_to :inspection_company, class_name: "InspectorCompany", optional: true

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :password, presence: true, length: {minimum: 6}, if: :password_digest_changed?
  validates :inspection_limit, numericality: {only_integer: true, greater_than_or_equal_to: -1}
  validates :time_display, inclusion: {in: %w[date time]}
  validates :theme, inclusion: {in: %w[light dark]}

  before_create :set_default_inspection_limit
  before_create :set_default_time_display
  before_save :downcase_email

  def can_create_inspection?
    has_inspection_company? &&
      inspection_company_active? &&
      within_inspection_limit?
  end

  def inspection_company_required_message
    return I18n.t("users.messages.company_not_activated") unless has_inspection_company?
    return I18n.t("users.messages.company_archived") unless inspection_company_active?
    I18n.t("users.messages.inspection_limit_reached")
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

  def has_inspection_company?
    inspection_company_id.present?
  end

  def inspection_company_active?
    inspection_company&.active?
  end

  def within_inspection_limit?
    inspection_limit == -1 || inspections.count < inspection_limit
  end

  def downcase_email
    self.email = email.downcase
  end

  def set_default_inspection_limit
    env_limit = ENV["LIMIT_INSPECTIONS"]
    self.inspection_limit = env_limit.present? ? env_limit.to_i : -1
  end

  def set_default_time_display
    self.time_display ||= "date"
  end
end
