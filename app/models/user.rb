# RPII Utility - Inspector authentication and credentials model
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  
  # Associations
  has_many :inspections, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :inspector_companies, dependent: :destroy
  has_many :error_logs, dependent: :destroy
  
  # RPII Credentials
  validates :rpii_registration_number, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  
  # Scopes
  scope :verified_inspectors, -> { where(rpii_verified: true) }
  scope :active, -> { where(deleted_at: nil) }
  
  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def valid_rpii_inspector?
    rpii_verified? && rpii_registration_number.present?
  end
  
  def inspection_statistics
    {
      total_inspections: inspections.count,
      passed_inspections: inspections.passed.count,
      failed_inspections: inspections.failed.count,
      pass_rate: calculate_pass_rate
    }
  end
  
  def equipment_statistics
    {
      total_units: units.count,
      units_by_type: units.group(:unit_type).count,
      recently_inspected: units.joins(:inspections).where(inspections: { inspection_date: 30.days.ago.. }).distinct.count
    }
  end
  
  def compliance_trends
    inspections.group_by_month(:inspection_date, last: 12).group(:passed).count
  end
  
  private
  
  def calculate_pass_rate
    return 0 if inspections.empty?
    (inspections.passed.count.to_f / inspections.count * 100).round(2)
  end
end