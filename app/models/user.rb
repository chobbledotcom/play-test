# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

# == Schema Information
#
# Table name: users
#
#  id                    :string(8)        not null, primary key
#  active_until          :date
#  address               :text
#  country               :string
#  email                 :string
#  last_active_at        :datetime
#  name                  :string
#  password_digest       :string
#  phone                 :string
#  postal_code           :string
#  rpii_inspector_number :string
#  rpii_verified_date    :datetime
#  theme                 :string           default("light")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inspection_company_id :string
#  webauthn_id           :string
#
# Indexes
#
#  index_users_on_email                  (email) UNIQUE
#  index_users_on_inspection_company_id  (inspection_company_id)
#  index_users_on_rpii_inspector_number  (rpii_inspector_number) UNIQUE WHERE rpii_inspector_number IS NOT NULL
#
class User < ApplicationRecord
  extend T::Sig
  include CustomIdGenerator

  # Type alias for RPII verification results
  RpiiVerificationResult = T.type_alias do
    T::Hash[Symbol, T.untyped]
  end

  has_secure_password

  has_many :inspections, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :credentials, dependent: :destroy
  has_one_attached :logo
  has_one_attached :signature
  validate :logo_must_be_image
  validate :signature_must_be_image

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

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  sig { returns(T::Boolean) }
  def is_active?
    active_until.nil? || active_until > Date.current
  end

  sig { returns(T::Boolean) }
  def can_delete_credentials?
    credentials.count > 1
  end

  alias_method :can_create_inspection?, :is_active?

  sig { returns(String) }
  def inactive_user_message
    I18n.t("users.messages.user_inactive")
  end

  sig { returns(T::Boolean) }
  def admin?
    admin_pattern = Rails.configuration.users.admin_emails_pattern
    return false if admin_pattern.blank?

    begin
      regex = Regexp.new(admin_pattern)
      regex.match?(email)
    rescue RegexpError
      false
    end
  end

  sig do
    params(
      value: T.nilable(T.any(Date, String, Time, ActiveSupport::TimeWithZone))
    ).void
  end
  def active_until=(value)
    @active_until_explicitly_set = true
    super
  end

  sig { returns(T::Boolean) }
  def has_company?
    inspection_company_id.present? || inspection_company.present?
  end

  sig { returns(T.nilable(String)) }
  def display_phone
    has_company? ? inspection_company.phone : phone
  end

  sig { returns(T.nilable(String)) }
  def display_address
    has_company? ? inspection_company.address : address
  end

  sig { returns(T.nilable(String)) }
  def display_country
    has_company? ? inspection_company.country : country
  end

  sig { returns(T.nilable(String)) }
  def display_postal_code
    has_company? ? inspection_company.postal_code : postal_code
  end

  sig { returns(RpiiVerificationResult) }
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

  sig { returns(T::Boolean) }
  def rpii_verified?
    rpii_verified_date.present?
  end

  sig { params(inspector: T::Hash[Symbol, T.untyped]).returns(RpiiVerificationResult) }
  def handle_valid_rpii_result(inspector)
    if inspector[:name].present? && names_match?(name, inspector[:name])
      update(rpii_verified_date: Time.current)
      {valid: true, inspector: inspector}
    else
      update(rpii_verified_date: nil)
      {valid: false, error: :name_mismatch, inspector: inspector}
    end
  end

  sig { returns(T::Boolean) }
  def has_seed_data?
    units.seed_data.exists? || inspections.seed_data.exists?
  end

  sig { returns(T::Boolean) }
  def validate_name?
    new_record? || name_changed?
  end

  sig { params(user_name: T.nilable(String), inspector_name: T.nilable(String)).returns(T::Boolean) }
  def names_match?(user_name, inspector_name)
    normalized_user = user_name.to_s.strip.downcase
    normalized_inspector = inspector_name.to_s.strip.downcase

    return true if normalized_user == normalized_inspector

    user_parts = normalized_user.split(/\s+/)
    inspector_parts = normalized_inspector.split(/\s+/)

    user_parts.all? { |part| inspector_parts.include?(part) }
  end

  sig { void }
  def downcase_email
    self.email = email.downcase
  end

  sig { void }
  def normalize_rpii_number
    self.rpii_inspector_number = nil if rpii_inspector_number.blank?
  end

  sig { void }
  def set_inactive_on_signup
    return if instance_variable_get(:@active_until_explicitly_set)

    self.active_until = Date.current - 1.day
  end

  sig { void }
  def logo_must_be_image
    return unless logo.attached?

    return if logo.blob.content_type.start_with?("image/")

    errors.add(:logo, "must be an image file")
    logo.purge
  end

  sig { void }
  def signature_must_be_image
    return unless signature.attached?

    return if signature.blob.content_type.start_with?("image/")

    errors.add(:signature, "must be an image file")
    signature.purge
  end
end
