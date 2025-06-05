# RPII Utility - Equipment being inspected model
class Unit < ApplicationRecord
  include CustomIdGenerator
  
  belongs_to :user
  has_many :inspections, dependent: :destroy
  
  # File attachments
  has_one_attached :photo
  
  # Validations
  validates :description, :manufacturer, :unit_type, :owner, presence: true
  validates :width, :length, :height, presence: true, numericality: { greater_than: 0, less_than: 200 }
  validates :serial_number, presence: true, uniqueness: { scope: :manufacturer }
  
  # Scopes
  scope :search, ->(query) { where("description ILIKE ? OR manufacturer ILIKE ? OR owner ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%") if query.present? }
  scope :by_type, ->(type) { where(unit_type: type) if type.present? }
  scope :with_recent_inspections, -> { joins(:inspections).where(inspections: { inspection_date: 1.year.ago.. }).distinct }
  
  # Enums
  enum unit_type: {
    bounce_house: 'bounce_house',
    slide: 'slide',
    combo_unit: 'combo_unit',
    obstacle_course: 'obstacle_course',
    totally_enclosed: 'totally_enclosed'
  }
  
  # Callbacks
  after_update :update_inspection_unit_data, if: :saved_changes_to_dimensions?
  
  # Methods
  def dimensions
    "#{width}m × #{length}m × #{height}m"
  end
  
  def last_inspection
    inspections.order(inspection_date: :desc).first
  end
  
  def last_inspection_status
    last_inspection&.passed? ? 'Passed' : 'Failed'
  end
  
  def inspection_history
    inspections.includes(:user).order(inspection_date: :desc)
  end
  
  def requires_enclosed_assessment?
    totally_enclosed?
  end
  
  def area
    width * length
  end
  
  def volume
    width * length * height
  end
  
  def next_inspection_due
    return nil unless last_inspection
    
    # Standard inspection interval is 12 months
    last_inspection.inspection_date + 12.months
  end
  
  def inspection_overdue?
    next_inspection_due && next_inspection_due < Date.current
  end
  
  def compliance_status
    return 'Never Inspected' unless last_inspection
    
    if inspection_overdue?
      'Overdue'
    elsif last_inspection.passed?
      'Compliant'
    else
      'Non-Compliant'
    end
  end
  
  def inspection_summary
    {
      total_inspections: inspections.count,
      passed_inspections: inspections.passed.count,
      failed_inspections: inspections.failed.count,
      last_inspection_date: last_inspection&.inspection_date,
      next_due_date: next_inspection_due,
      compliance_status: compliance_status
    }
  end
  
  private
  
  def saved_changes_to_dimensions?
    saved_change_to_width? || saved_change_to_length? || saved_change_to_height?
  end
  
  def update_inspection_unit_data
    # Update any draft inspections with new unit dimensions
    inspections.draft.each do |inspection|
      inspection.log_audit_action('unit_updated', user, 'Unit dimensions updated')
    end
  end
end