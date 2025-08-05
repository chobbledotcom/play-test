# typed: true
# frozen_string_literal: true

class InspectorCompany < ApplicationRecord
  extend T::Sig

  include CustomIdGenerator
  include FormConfigurable
  include ValidationConfigurable

  has_many :inspections, dependent: :destroy

  # Override to filter admin-only fields
  sig {
    params(user: T.nilable(User)).returns(
      T::Array[
        T::Hash[
          Symbol,
          T.any(
            String,
            T::Array[T::Hash[Symbol, T.any(String, Symbol, Integer, T::Boolean, T::Hash[Symbol, T.any(String, Integer, T::Boolean)])]]
          )
        ]
      ]
    )
  }
  def self.form_fields(user: nil)
    fields = super

    # Remove notes field unless user is admin
    unless user&.admin?
      fields.each do |fieldset|
        fieldset[:fields].delete_if { |field| field[:field] == :notes }
      end
    end

    fields
  end

  # File attachments
  has_one_attached :logo

  # Validations
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :archived, -> { where(active: false) }
  scope :by_status, ->(status) {
    case status&.to_s
    when "active" then active
    when "archived" then archived
    when "all" then all
    else all # Default to all companies when no parameter provided
    end
  }
  scope :search_by_term, ->(term) {
    return all if term.blank?
    where("name LIKE ?", "%#{term}%")
  }

  # Callbacks
  before_save :normalize_phone_number

  # Methods
  # Credentials validation moved to individual inspector level (User model)

  sig { returns(String) }
  def full_address
    [address, city, postal_code].compact.join(", ")
  end

  sig { returns(Integer) }
  def inspection_count
    inspections.count
  end

  sig { params(limit: Integer).returns(ActiveRecord::Relation) }
  def recent_inspections(limit = 10)
    # Will be enhanced when Unit relationship is added
    inspections.order(inspection_date: :desc).limit(limit)
  end

  sig { params(total: T.nilable(Integer), passed: T.nilable(Integer)).returns(Float) }
  def pass_rate(total = nil, passed = nil)
    total ||= inspections.count
    passed ||= inspections.passed.count
    return 0.0 if total == 0
    (passed.to_f / total * 100).round(2)
  end

  sig { returns(T::Hash[Symbol, T.any(Integer, Float)]) }
  def company_statistics
    # Use group to get all counts in a single query
    counts = inspections.group(:passed).count
    passed_count = counts[true] || 0
    failed_count = counts[false] || 0
    total_count = passed_count + failed_count

    {
      total_inspections: total_count,
      passed_inspections: passed_count,
      failed_inspections: failed_count,
      pass_rate: pass_rate(total_count, passed_count),
      active_since: created_at.year
    }
  end

  sig { returns(T.nilable(ActiveStorage::Attached::One)) }
  def logo_url
    logo.attached? ? logo : nil
  end

  private

  sig { void }
  def normalize_phone_number
    return if phone.blank?

    # Remove all non-digit characters
    self.phone = phone.gsub(/\D/, "")
  end
end
