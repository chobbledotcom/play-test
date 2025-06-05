# RPII Utility - Company credentials and branding model
class InspectorCompany < ApplicationRecord
  include CustomIdGenerator
  
  belongs_to :user
  has_many :inspections, dependent: :destroy
  
  # File attachments
  has_one_attached :logo
  
  # Validations
  validates :name, presence: true
  validates :rpii_registration_number, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, presence: true
  validates :address, presence: true
  
  # Scopes
  scope :verified, -> { where(rpii_verified: true) }
  scope :active, -> { where(active: true) }
  
  # Callbacks
  before_save :normalize_phone_number
  after_update :update_inspection_company_data, if: :saved_change_to_name?
  
  # Methods
  def has_valid_credentials?
    rpii_registration_number.present? && rpii_verified?
  end
  
  def full_address
    [address, city, state, postal_code].compact.join(', ')
  end
  
  def inspection_count
    inspections.count
  end
  
  def recent_inspections(limit = 10)
    inspections.includes(:unit).order(inspection_date: :desc).limit(limit)
  end
  
  def pass_rate
    return 0 if inspections.empty?
    (inspections.passed.count.to_f / inspections.count * 100).round(2)
  end
  
  def company_statistics
    {
      total_inspections: inspections.count,
      passed_inspections: inspections.passed.count,
      failed_inspections: inspections.failed.count,
      pass_rate: pass_rate,
      active_since: created_at.year,
      verified: rpii_verified?
    }
  end
  
  def logo_url
    logo.attached? ? logo : nil
  end
  
  private
  
  def normalize_phone_number
    return unless phone.present?
    
    # Remove all non-digit characters
    self.phone = phone.gsub(/\D/, '')
  end
  
  def update_inspection_company_data
    # Update any draft inspections with new company name
    inspections.draft.each do |inspection|
      inspection.update(inspection_company_name: name)
      inspection.log_audit_action('company_updated', user, 'Company name updated')
    end
  end
end