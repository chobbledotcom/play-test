# RPII Utility - Unit model for bounce house inspection system
class Unit < ApplicationRecord
  self.table_name = "units"
  include CustomIdGenerator
  include HasDimensions

  belongs_to :user
  has_many :inspections, dependent: :destroy

  # File attachments
  has_one_attached :photo

  # All fields are required for Units
  validates :name, :serial, :description, :manufacturer, :owner, presence: true
  validates :serial, uniqueness: {scope: [:user_id]}

  # Override HasDimensions validations for required basic dimensions
  validates :width, :length, :height, presence: true, numericality: {greater_than: 0, less_than: 200}

  # Scopes - enhanced from original Equipment and new Unit functionality
  scope :search, ->(query) {
    if query.present?
      where("serial LIKE ? OR name LIKE ? OR description LIKE ? OR manufacturer LIKE ? OR owner LIKE ?",
        "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
    else
      all
    end
  }
  scope :with_slide, -> { where(has_slide: true) }
  scope :without_slide, -> { where(has_slide: false) }
  scope :with_recent_inspections, -> { joins(:inspections).where(inspections: {inspection_date: SafetyStandard::REINSPECTION_INTERVAL_DAYS.days.ago..}).distinct }

  # Callbacks
  before_create :generate_custom_id
  after_update :update_inspection_unit_data, if: :saved_changes_to_dimensions?

  # Additional methods beyond HasDimensions concern

  def last_inspection
    inspections.order(inspection_date: :desc).first
  end

  def last_inspection_status
    last_inspection&.passed? ? "Passed" : "Failed"
  end

  def inspection_history
    inspections.includes(:user).order(inspection_date: :desc)
  end

  def requires_enclosed_assessment?
    is_totally_enclosed?
  end

  def next_inspection_due
    return nil unless last_inspection
    # Standard inspection interval using safety standard constant
    last_inspection.inspection_date + SafetyStandard::REINSPECTION_INTERVAL_DAYS.days
  end

  def inspection_overdue?
    return false unless next_inspection_due
    next_inspection_due < Date.current
  end

  def compliance_status
    return "Never Inspected" unless last_inspection

    if inspection_overdue?
      "Overdue"
    elsif last_inspection.passed?
      "Compliant"
    else
      "Non-Compliant"
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

  def self.overdue
    # Find units where their most recent inspection is older than the reinspection interval
    # Using Date.current instead of Date.today for consistency with Rails timezone handling
    joins(:inspections)
      .group("units.id")
      .having("MAX(inspections.inspection_date) <= ?", Date.current - SafetyStandard::REINSPECTION_INTERVAL_DAYS.days)
  end

  private

  def saved_changes_to_dimensions?
    # Use the dimension_changed? method from HasDimensions, but for saved changes
    dimension_attributes.keys.any? { |attr| saved_change_to_attribute?(attr) }
  end

  def update_inspection_unit_data
    # Update any draft inspections with new unit dimensions
    inspections.each do |inspection|
      inspection.log_audit_action("unit_updated", user, "Unit dimensions updated")
    end
  end
end
