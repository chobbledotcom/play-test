class Inspection < ApplicationRecord
  include CustomIdGenerator
  include HasDimensions

  belongs_to :user
  belongs_to :unit, optional: true
  belongs_to :inspector_company, optional: true

  # Assessment associations (normalized from single table)
  has_one :user_height_assessment, class_name: "UserHeightAssessment",
    dependent: :destroy
  alias_method :tallest_user_height_assessment, :user_height_assessment
  has_one :slide_assessment, class_name: "SlideAssessment",
    dependent: :destroy
  has_one :structure_assessment, class_name: "StructureAssessment",
    dependent: :destroy
  has_one :anchorage_assessment, class_name: "AnchorageAssessment",
    dependent: :destroy
  has_one :materials_assessment, class_name: "MaterialsAssessment",
    dependent: :destroy
  has_one :fan_assessment, class_name: "FanAssessment", dependent: :destroy
  has_one :enclosed_assessment, class_name: "EnclosedAssessment",
    dependent: :destroy

  # Accept nested attributes for all assessments
  accepts_nested_attributes_for :user_height_assessment, :slide_assessment,
    :structure_assessment, :anchorage_assessment, :materials_assessment,
    :fan_assessment, :enclosed_assessment

  # Validations - allow drafts to be incomplete
  validates :inspection_location, presence: true, if: :complete?
  validates :inspection_date, presence: true
  validates :unique_report_number, presence: true,
    uniqueness: {scope: :user_id}, if: :complete?

  # Step/Ramp Size validations
  validates :step_ramp_size,
    numericality: {greater_than_or_equal_to: 0},
    allow_blank: true
  validates :step_ramp_size_pass,
    inclusion: {in: [true, false]},
    allow_nil: true

  # Critical Fall Off Height validations
  validates :critical_fall_off_height,
    numericality: {greater_than_or_equal_to: 0},
    allow_blank: true
  validates :critical_fall_off_height_pass,
    inclusion: {in: [true, false]},
    allow_nil: true

  # Unit Pressure validations
  validates :unit_pressure,
    numericality: {greater_than_or_equal_to: 0},
    allow_blank: true
  validates :unit_pressure_pass,
    inclusion: {in: [true, false]},
    allow_nil: true

  # Trough validations
  validates :trough_depth,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true
  validates :trough_adjacent_panel_width,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true
  validates :trough_pass, inclusion: {in: [true, false]}, allow_nil: true

  # Entrapment validation
  validates :entrapment_pass, inclusion: {in: [true, false]}, allow_nil: true

  # Markings/ID validation
  validates :markings_id_pass, inclusion: {in: [true, false]}, allow_nil: true

  # Grounding validation
  validates :grounding_pass, inclusion: {in: [true, false]}, allow_nil: true

  # Additional pass/fail validations
  validates :clamber_netting_pass,
    inclusion: {in: [true, false]},
    allow_nil: true
  validates :retention_netting_pass,
    inclusion: {in: [true, false]},
    allow_nil: true
  validates :zips_pass, inclusion: {in: [true, false]}, allow_nil: true
  validates :windows_pass, inclusion: {in: [true, false]}, allow_nil: true
  validates :artwork_pass, inclusion: {in: [true, false]}, allow_nil: true
  validates :exit_sign_visible_pass,
    inclusion: {in: [true, false]},
    allow_nil: true

  # Callbacks
  before_validation :set_inspector_company_from_user, on: :create
  before_validation :copy_unit_values, on: :create, if: :unit_id_changed?
  before_create :generate_unique_report_number, if: :complete?
  before_create :copy_unit_values
  before_save :auto_determine_pass_fail, if: :all_assessments_complete?

  # Scopes
  scope :seed_data, -> { where(is_seed: true) }
  scope :non_seed_data, -> { where(is_seed: false) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :complete, -> { where.not(complete_date: nil) }
  scope :draft, -> { where(complete_date: nil) }
  scope :search, ->(query) {
    if query.present?
      joins("LEFT JOIN units ON units.id = inspections.unit_id")
        .where(search_conditions, *search_values(query))
    else
      all
    end
  }
  scope :filter_by_result, ->(result) {
    case result
    when "passed" then where(passed: true)
    when "failed" then where(passed: false)
    end
  }
  scope :filter_by_unit, ->(unit_id) {
    where(unit_id: unit_id) if unit_id.present?
  }
  scope :filter_by_owner, ->(owner) {
    if owner.present?
      joins(:unit).where("units.owner = ?", owner)
    else
      all
    end
  }
  scope :filter_by_inspection_location, ->(location) {
    where(inspection_location: location) if location.present?
  }
  scope :filter_by_date_range, ->(start_date, end_date) {
    range = start_date..end_date
    where(inspection_date: range) if both_dates_present?(start_date, end_date)
  }
  scope :overdue, -> { where("inspection_date < ?", Date.today - 1.year) }

  # Helper methods for scopes
  def self.search_conditions
    "inspections.inspection_location LIKE ? OR inspections.id LIKE ? OR " \
    "inspections.unique_report_number LIKE ? OR units.serial LIKE ? OR " \
    "units.manufacturer LIKE ? OR units.name LIKE ?"
  end

  def self.search_values(query) = Array.new(6) { "%#{query}%" }

  def self.both_dates_present?(start_date, end_date) =
    start_date.present? && end_date.present?

  # Delegate methods to unit
  delegate :name, :serial, :manufacturer, to: :unit, allow_nil: true

  # Calculated fields
  def reinspection_date
    return nil unless inspection_date.present?
    inspection_date + 1.year
  end

  # Check if inspection is complete (not draft)
  def complete?
    complete_date.present?
  end

  # URL routing based on completion status
  def primary_url_path
    if complete?
      "inspection_path(self)"
    else
      "edit_inspection_path(self)"
    end
  end

  def preferred_path
    if complete?
      Rails.application.routes.url_helpers.inspection_path(self)
    else
      Rails.application.routes.url_helpers.edit_inspection_path(self)
    end
  end

  # Advanced methods
  def can_be_completed?
    unit.present? && all_assessments_complete?
  end

  def completion_status
    complete = complete?
    all_assessments_complete = all_assessments_complete?
    missing_assessments = get_missing_assessments
    can_be_completed = can_be_completed?

    {
      complete:,
      all_assessments_complete:,
      missing_assessments:,
      can_be_completed:
    }
  end

  def get_missing_assessments
    missing = []
    missing << "Unit" unless unit.present?
    missing << "User Height" unless user_height_assessment&.complete?
    missing << "Structure" unless structure_assessment&.complete?
    missing << "Anchorage" unless anchorage_assessment&.complete?
    missing << "Materials" unless materials_assessment&.complete?
    missing << "Fan" unless fan_assessment&.complete?
    missing << "Slide" if has_slide? && !slide_assessment&.complete?
    if is_totally_enclosed? && !enclosed_assessment&.complete?
      missing << "Enclosed"
    end
    missing
  end

  def complete!(user)
    update!(complete_date: Time.current)
    log_audit_action("completed", user, "Inspection completed")
  end

  def duplicate_for_user(user)
    new_inspection = dup
    new_inspection.user = user
    new_inspection.complete_date = nil
    new_inspection.unique_report_number = nil
    new_inspection.passed = nil
    new_inspection.save!

    # Duplicate all assessments
    duplicate_assessments(new_inspection)

    new_inspection
  end

  def validate_completeness
    assessment_validation_data.filter_map do |name, assessment, message|
      message if assessment&.present? && !assessment.complete?
    end
  end

  def pass_fail_summary
    total_checks = total_safety_checks
    return zero_summary if total_checks == 0

    passed_checks = passed_safety_checks
    failed_checks = failed_safety_checks
    percentage = passed_checks.to_f / total_checks * 100
    pass_percentage = percentage.round(2)

    {
      failed_checks:,
      pass_percentage:,
      passed_checks:,
      total_checks:
    }
  end

  def zero_summary
    {
      failed_checks: 0,
      pass_percentage: 0,
      passed_checks: 0,
      total_checks: 0
    }
  end

  def log_audit_action(action, user, details)
    # Simple logging for now - could be enhanced with audit log table later
    message = "Inspection #{id}: #{action} by #{user&.email} - #{details}"
    Rails.logger.info(message)
  end

  private

  def generate_unique_report_number
    return if unique_report_number.present?

    date_part = Date.current.strftime("%Y%m%d")
    hex_part = SecureRandom.hex(4).upcase
    self.unique_report_number = "RPII-#{date_part}-#{hex_part}"
  end

  def copy_unit_values
    return unless unit.present?

    # Copy all dimensions and boolean flags from unit using the concern method
    copy_attributes_from(unit)
  end

  def set_inspector_company_from_user
    self.inspector_company_id ||= user.inspection_company_id
  end

  def all_assessments_complete?
    return false unless has_assessments?

    required_assessment_completions.all?
  end

  def required_assessment_completions
    base_completions = [
      anchorage_assessment&.complete?,
      fan_assessment&.complete?,
      materials_assessment&.complete?,
      structure_assessment&.complete?,
      user_height_assessment&.complete?
    ]

    base_completions << slide_assessment&.complete? if has_slide?
    base_completions << enclosed_assessment&.complete? if is_totally_enclosed?
    base_completions
  end

  def all_assessments
    base_assessments = [
      anchorage_assessment,
      fan_assessment,
      materials_assessment,
      slide_assessment,
      structure_assessment,
      user_height_assessment
    ]
    base_assessments << enclosed_assessment if is_totally_enclosed?
    base_assessments
  end

  def has_assessments?
    user_height_assessment.present? || slide_assessment.present? ||
      structure_assessment.present? || anchorage_assessment.present? ||
      materials_assessment.present? || fan_assessment.present?
  end

  def auto_determine_pass_fail
    self.passed = all_safety_checks_pass?
  end

  def all_safety_checks_pass?
    return true unless has_assessments?

    # Business logic to determine overall pass/fail
    critical_failures = [
      structure_assessment&.has_critical_failures?,
      anchorage_assessment&.has_critical_failures?,
      materials_assessment&.has_critical_failures?
    ].any?

    !critical_failures && meet_safety_thresholds?
  end

  def meet_safety_thresholds?
    return true unless has_assessments?

    height_ok = user_height_assessment&.meets_height_requirements? != false
    runout_ok = slide_assessment&.meets_runout_requirements? != false
    anchor_ok = anchorage_assessment&.meets_anchor_requirements? != false

    height_ok && runout_ok && anchor_ok
  end

  def total_safety_checks
    return 0 unless has_assessments?

    all_assessments.compact.sum do |assessment|
      case assessment
      when MaterialsAssessment
        MaterialsAssessment::SAFETY_CHECK_COUNT
      else
        assessment.safety_check_count
      end
    end
  end

  def passed_safety_checks
    return 0 unless has_assessments?

    all_assessments.compact.sum(&:passed_checks_count)
  end

  def failed_safety_checks = total_safety_checks - passed_safety_checks

  def duplicate_assessments(new_inspection)
    assessments_to_duplicate.each do |assessment|
      duplicate_single_assessment(assessment, new_inspection)
    end
  end

  private

  def assessment_validation_data
    assessment_types = %i[
      anchorage
      enclosed
      fan
      materials
      slide
      structure
      user_height
    ]

    assessment_types.map do |type|
      assessment = send("#{type}_assessment")
      message = I18n.t("inspections.validation.#{type}_incomplete")
      [type, assessment, message]
    end
  end

  def assessments_to_duplicate
    assessments = [
      user_height_assessment, slide_assessment, structure_assessment,
      anchorage_assessment, materials_assessment, fan_assessment
    ]
    assessments << enclosed_assessment if is_totally_enclosed?
    assessments.compact
  end

  def duplicate_single_assessment(assessment, new_inspection)
    assessment.dup.tap do |duplicated|
      duplicated.inspection = new_inspection
      duplicated.save!
    end
  end
end
