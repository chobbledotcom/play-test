# RPII Utility - Main inspection record model
class Inspection < ApplicationRecord
  include CustomIdGenerator
  
  belongs_to :user
  belongs_to :unit
  belongs_to :inspector_company
  
  # Assessment associations (normalized from single table)
  has_one :user_height_assessment, dependent: :destroy
  has_one :slide_assessment, dependent: :destroy
  has_one :structure_assessment, dependent: :destroy
  has_one :anchorage_assessment, dependent: :destroy
  has_one :materials_assessment, dependent: :destroy
  has_one :fan_assessment, dependent: :destroy
  has_one :enclosed_assessment, dependent: :destroy
  has_many :inspection_audit_logs, dependent: :destroy
  
  # Accept nested attributes for all assessments
  accepts_nested_attributes_for :user_height_assessment, :slide_assessment,
                               :structure_assessment, :anchorage_assessment,
                               :materials_assessment, :fan_assessment,
                               :enclosed_assessment
  
  # Validations
  validates :inspection_date, presence: true
  validates :place_inspected, presence: true
  validates :rpii_registration_number, presence: true
  validates :unique_report_number, presence: true, uniqueness: { scope: :user_id }
  validates :inspection_company_name, presence: true
  
  # Status validations
  validates :status, inclusion: { in: %w[draft in_progress completed finalized] }
  validate :cannot_finalize_incomplete_inspection, if: :finalizing?
  
  # Callbacks
  before_create :generate_unique_report_number
  before_save :auto_determine_pass_fail, if: :all_assessments_complete?
  after_create :create_assessment_records
  after_update :log_status_change, if: :saved_change_to_status?
  
  # Scopes
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :completed, -> { where(status: 'completed') }
  scope :finalized, -> { where(status: 'finalized') }
  scope :search, ->(query) { where("inspection_company_name ILIKE ? OR place_inspected ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }
  scope :filter_by_status, ->(status) { where(status: status) if status.present? }
  scope :filter_by_date_range, ->(start_date, end_date) { where(inspection_date: start_date..end_date) if start_date.present? && end_date.present? }
  
  # State machine for inspection workflow
  enum status: {
    draft: 'draft',
    in_progress: 'in_progress', 
    completed: 'completed',
    finalized: 'finalized'
  }
  
  # Methods
  def can_be_finalized?
    all_assessments_complete? && status == 'completed'
  end
  
  def finalize!(user)
    update!(
      status: 'finalized',
      finalized_at: Time.current,
      finalized_by: user
    )
    log_audit_action('finalized', user, 'Inspection finalized and locked')
  end
  
  def duplicate_for_user(user)
    new_inspection = self.dup
    new_inspection.user = user
    new_inspection.status = 'draft'
    new_inspection.unique_report_number = nil
    new_inspection.passed = nil
    new_inspection.finalized_at = nil
    new_inspection.finalized_by = nil
    new_inspection.save!
    
    # Duplicate all assessments
    duplicate_assessments(new_inspection)
    
    new_inspection
  end
  
  def validate_completeness
    errors = []
    
    # Check each assessment section
    errors << "User Height Assessment incomplete" unless user_height_assessment&.complete?
    errors << "Slide Assessment incomplete" unless slide_assessment&.complete?
    errors << "Structure Assessment incomplete" unless structure_assessment&.complete?
    errors << "Anchorage Assessment incomplete" unless anchorage_assessment&.complete?
    errors << "Materials Assessment incomplete" unless materials_assessment&.complete?
    errors << "Fan Assessment incomplete" unless fan_assessment&.complete?
    errors << "Totally Enclosed Assessment incomplete" if unit.totally_enclosed? && !enclosed_assessment&.complete?
    
    errors
  end
  
  def pass_fail_summary
    {
      total_checks: total_safety_checks,
      passed_checks: passed_safety_checks,
      failed_checks: failed_safety_checks,
      pass_percentage: (passed_safety_checks.to_f / total_safety_checks * 100).round(2)
    }
  end
  
  def sync_mobile_data(mobile_data)
    # Handle offline mobile data synchronization
    transaction do
      update!(mobile_data.except('assessments'))
      sync_assessments(mobile_data['assessments']) if mobile_data['assessments']
    end
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  
  private
  
  def generate_unique_report_number
    self.unique_report_number = "RPII-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end
  
  def create_assessment_records
    create_user_height_assessment!
    create_slide_assessment!
    create_structure_assessment!
    create_anchorage_assessment!
    create_materials_assessment!
    create_fan_assessment!
    create_enclosed_assessment! if unit.totally_enclosed?
    
    log_audit_action('created', user, 'Inspection created with assessment records')
  end
  
  def all_assessments_complete?
    required_assessments = [
      user_height_assessment&.complete?,
      slide_assessment&.complete?,
      structure_assessment&.complete?,
      anchorage_assessment&.complete?,
      materials_assessment&.complete?,
      fan_assessment&.complete?
    ]
    
    # Add enclosed assessment if required
    required_assessments << enclosed_assessment&.complete? if unit.totally_enclosed?
    
    required_assessments.all?
  end
  
  def auto_determine_pass_fail
    self.passed = all_safety_checks_pass?
  end
  
  def all_safety_checks_pass?
    # Business logic to determine overall pass/fail
    critical_failures = [
      structure_assessment&.has_critical_failures?,
      anchorage_assessment&.has_critical_failures?,
      materials_assessment&.has_critical_failures?,
      fan_assessment&.has_critical_failures?
    ].any?
    
    !critical_failures && meet_safety_thresholds?
  end
  
  def meet_safety_thresholds?
    user_height_assessment&.meets_height_requirements? &&
    slide_assessment&.meets_runout_requirements? &&
    anchorage_assessment&.meets_anchor_requirements?
  end
  
  def finalizing?
    status_changed? && status == 'finalized'
  end
  
  def cannot_finalize_incomplete_inspection
    errors.add(:status, "Cannot finalize incomplete inspection") unless can_be_finalized?
  end
  
  def total_safety_checks
    assessments = [user_height_assessment, slide_assessment, structure_assessment,
                   anchorage_assessment, materials_assessment, fan_assessment]
    assessments << enclosed_assessment if unit.totally_enclosed?
    
    assessments.compact.sum(&:safety_check_count)
  end
  
  def passed_safety_checks
    assessments = [user_height_assessment, slide_assessment, structure_assessment,
                   anchorage_assessment, materials_assessment, fan_assessment]
    assessments << enclosed_assessment if unit.totally_enclosed?
    
    assessments.compact.sum(&:passed_checks_count)
  end
  
  def failed_safety_checks
    total_safety_checks - passed_safety_checks
  end
  
  def duplicate_assessments(new_inspection)
    user_height_assessment&.dup&.tap { |a| a.inspection = new_inspection; a.save! }
    slide_assessment&.dup&.tap { |a| a.inspection = new_inspection; a.save! }
    structure_assessment&.dup&.tap { |a| a.inspection = new_inspection; a.save! }
    anchorage_assessment&.dup&.tap { |a| a.inspection = new_inspection; a.save! }
    materials_assessment&.dup&.tap { |a| a.inspection = new_inspection; a.save! }
    fan_assessment&.dup&.tap { |a| a.inspection = new_inspection; a.save! }
    enclosed_assessment&.dup&.tap { |a| a.inspection = new_inspection; a.save! } if unit.totally_enclosed?
  end
  
  def log_status_change
    log_audit_action('status_changed', user, "Status changed from #{status_before_last_save} to #{status}")
  end
  
  def log_audit_action(action, user, details)
    inspection_audit_logs.create!(
      action: action,
      user: user,
      details: details,
      created_at: Time.current
    )
  end
  
  def sync_assessments(assessments_data)
    assessments_data.each do |type, data|
      assessment = send("#{type}_assessment")
      assessment&.update!(data)
    end
  end
end