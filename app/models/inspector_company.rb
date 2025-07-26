class InspectorCompany < ApplicationRecord
  include CustomIdGenerator
  include FormConfigurable

  has_many :inspections, dependent: :destroy

  # Override to filter admin-only fields
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
  validates :name, presence: true
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validates :phone, presence: true
  validates :address, presence: true

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

  def full_address
    [address, city, postal_code].compact.join(", ")
  end

  def inspection_count
    inspections.count
  end

  def recent_inspections(limit = 10)
    # Will be enhanced when Unit relationship is added
    inspections.order(inspection_date: :desc).limit(limit)
  end

  def pass_rate(total = nil, passed = nil)
    total ||= inspections.count
    passed ||= inspections.passed.count
    return 0 if total == 0
    (passed.to_f / total * 100).round(2)
  end

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

  def logo_url
    logo.attached? ? logo : nil
  end

  private

  def normalize_phone_number
    return if phone.blank?

    # Remove all non-digit characters
    self.phone = phone.gsub(/\D/, "")
  end
end
