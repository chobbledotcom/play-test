class User < ApplicationRecord
  include CustomIdGenerator

  has_secure_password
  has_many :inspections, dependent: :destroy
  has_many :units, dependent: :destroy
  belongs_to :inspection_company, class_name: "InspectorCompany", optional: true

  email_format_options = {with: URI::MailTo::EMAIL_REGEXP}
  validates :email, presence: true, uniqueness: true,
    format: email_format_options
  password_length_options = {minimum: 6}
  validates :password, presence: true, length: password_length_options,
    if: :password_digest_changed?
  validates :name, presence: true, if: :validate_name?
  validates :rpii_inspector_number, presence: true
  validates :time_display, inclusion: {in: %w[date time]}
  validates :theme, inclusion: {in: %w[light dark]}
  # Contact fields are only required for users without companies
  # when they need to generate PDFs
  # For now, we'll make them optional during signup and enforce them when needed

  before_create :set_default_time_display
  before_create :set_inactive_on_signup
  before_save :downcase_email

  def is_active?
    active_until.nil? || active_until >= Date.current
  end

  # Temporary alias - will be removed later
  alias_method :can_create_inspection?, :is_active?

  def inactive_user_message
    I18n.t("users.messages.user_inactive")
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

  def active_until=(value)
    @active_until_explicitly_set = true
    super
  end

  def has_company?
    inspection_company_id.present? || inspection_company.present?
  end

  def display_phone
    has_company? ? inspection_company.phone : phone
  end

  def display_address
    has_company? ? inspection_company.address : address
  end

  def display_country
    has_company? ? inspection_company.country : country
  end

  def display_postal_code
    has_company? ? inspection_company.postal_code : postal_code
  end

  private

  def validate_name?
    # Skip name validation if we're only updating settings fields
    # Name is required for new records and when explicitly being updated
    new_record? || name_changed?
  end

  def downcase_email
    self.email = email.downcase
  end

  def set_default_time_display
    self.time_display ||= "date"
  end

  def set_inactive_on_signup
    # Set active_until to yesterday so user is inactive by default
    # Admin will need to extend this date for user to become active
    # Only set default if active_until was not explicitly provided
    unless instance_variable_get(:@active_until_explicitly_set)
      self.active_until = Date.current - 1.day
    end
  end
end
