class User < ApplicationRecord
  include CustomIdGenerator

  has_secure_password

  has_many :inspections, dependent: :destroy
  has_many :units, dependent: :destroy
  has_one_attached :logo
  validate :logo_must_be_image

  belongs_to :inspection_company,
    class_name: "InspectorCompany",
    optional: true

  validates :email,
    presence: true,
    uniqueness: true,
    format: {with: URI::MailTo::EMAIL_REGEXP}

  validates :password,
    presence: true,
    length: {minimum: 6},
    if: :password_digest_changed?

  validates :name,
    presence: true,
    if: :validate_name?

  validates :rpii_inspector_number,
    uniqueness: true,
    allow_nil: true

  validates :theme,
    inclusion: {in: %w[default light dark]}

  before_save :downcase_email
  before_save :normalize_rpii_number
  before_create :set_inactive_on_signup

  def is_active?
    active_until.nil? || active_until >= Date.current
  end

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

  def verify_rpii_inspector_number
    if rpii_inspector_number.blank?
      return {valid: false, error: :blank_number}
    elsif name.blank?
      return {valid: false, error: :blank_name}
    end

    result = RpiiVerificationService.verify(rpii_inspector_number)

    if result[:valid]
      handle_valid_rpii_result(result[:inspector])
    else
      update(rpii_verified_date: nil)
      {valid: false, error: :not_found}
    end
  end

  def rpii_verified?
    rpii_verified_date.present?
  end

  def handle_valid_rpii_result(inspector)
    if inspector[:name].present? && names_match?(name, inspector[:name])
      update(rpii_verified_date: Time.current)
      {valid: true, inspector: inspector}
    else
      update(rpii_verified_date: nil)
      {valid: false, error: :name_mismatch, inspector: inspector}
    end
  end

  def has_seed_data?
    units.seed_data.exists? || inspections.seed_data.exists?
  end

  def validate_name?
    new_record? || name_changed?
  end

  def names_match?(user_name, inspector_name)
    normalized_user = user_name.to_s.strip.downcase
    normalized_inspector = inspector_name.to_s.strip.downcase

    return true if normalized_user == normalized_inspector

    user_parts = normalized_user.split(/\s+/)
    inspector_parts = normalized_inspector.split(/\s+/)

    user_parts.all? { |part| inspector_parts.include?(part) }
  end

  def downcase_email
    self.email = email.downcase
  end

  def normalize_rpii_number
    self.rpii_inspector_number = nil if rpii_inspector_number.blank?
  end

  def set_inactive_on_signup
    unless instance_variable_get(:@active_until_explicitly_set)
      self.active_until = Date.current - 1.day
    end
  end

  def logo_must_be_image
    return unless logo.attached?

    unless logo.blob.content_type.start_with?("image/")
      errors.add(:logo, "must be an image file")
      logo.purge
    end
  end
end
