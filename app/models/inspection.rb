class Inspection < ApplicationRecord
  include CustomIdGenerator

  ASSESSMENT_TYPES = {
    anchorage_assessment: Assessments::AnchorageAssessment,
    enclosed_assessment: Assessments::EnclosedAssessment,
    fan_assessment: Assessments::FanAssessment,
    materials_assessment: Assessments::MaterialsAssessment,
    slide_assessment: Assessments::SlideAssessment,
    structure_assessment: Assessments::StructureAssessment,
    user_height_assessment: Assessments::UserHeightAssessment
  }.freeze

  belongs_to :user
  belongs_to :unit, optional: true
  belongs_to :inspector_company, optional: true

  # Assessment associations (normalized from single table)
  ASSESSMENT_TYPES.each do |assessment_name, assessment_class|
    has_one assessment_name,
      class_name: assessment_class.name,
      dependent: :destroy
  end

  alias_method :tallest_user_height_assessment, :user_height_assessment

  # Accept nested attributes for all assessments
  accepts_nested_attributes_for(*ASSESSMENT_TYPES.keys)

  # Validations - allow drafts to be incomplete
  validates :inspection_location, presence: true, if: :complete?
  validates :inspection_date, presence: true
  validates :unique_report_number,
    uniqueness: {scope: :user_id, allow_blank: true}

  # Callbacks
  before_validation :set_inspector_company_from_user, on: :create
  before_save :auto_determine_pass_fail, if: :all_assessments_complete?
  after_create :create_assessments

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

  # Calculated fields
  def reinspection_date
    return nil unless inspection_date.present?
    inspection_date + 1.year
  end

  def area
    return nil unless width && height
    width * height
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

  def can_mark_complete? = can_be_completed?

  def completion_errors
    errors = []
    errors << "Unit is required" unless unit.present?
    errors += get_missing_assessments.map { |assessment| "#{assessment} Assessment incomplete" }
    errors
  end

  def get_missing_assessments
    missing = []
    
    # Check for missing unit first
    missing << "Unit" unless unit.present?
    
    # Check for missing assessments using a mapping to match expected values
    assessment_names = {
      user_height_assessment: "User Height",
      structure_assessment: "Structure",
      anchorage_assessment: "Anchorage",
      materials_assessment: "Materials",
      fan_assessment: "Fan",
      slide_assessment: "Slide",
      enclosed_assessment: "Enclosed"
    }
    
    assessment_names.each do |assessment_name, display_name|
      # Skip slide assessment if unit doesn't have a slide
      next if assessment_name == :slide_assessment && !has_slide?
      # Skip enclosed assessment if unit is not totally enclosed
      next if assessment_name == :enclosed_assessment && !is_totally_enclosed?
      
      assessment = send(assessment_name)
      missing << display_name unless assessment&.complete?
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
      # Skip slide assessment if unit doesn't have a slide
      next if name == :slide && !has_slide?
      # Skip enclosed assessment if unit is not totally enclosed
      next if name == :enclosed && !is_totally_enclosed?

      message if assessment&.present? && !assessment.complete?
    end
  end

  def pass_fail_summary
    total_checks = total_pass_columns
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

  def create_assessments
    create_user_height_assessment! unless user_height_assessment
    create_slide_assessment! unless slide_assessment
    create_structure_assessment! unless structure_assessment
    create_anchorage_assessment! unless anchorage_assessment
    create_materials_assessment! unless materials_assessment
    create_fan_assessment! unless fan_assessment
    create_enclosed_assessment! unless enclosed_assessment
  end

  def set_inspector_company_from_user
    self.inspector_company_id ||= user.inspection_company_id
  end

  def all_assessments_complete?
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

  def auto_determine_pass_fail
    self.passed = all_safety_checks_pass?
  end

  def all_safety_checks_pass?
    # Business logic to determine overall pass/fail
    critical_failures = [
      structure_assessment&.has_critical_failures?,
      anchorage_assessment&.has_critical_failures?,
      materials_assessment&.has_critical_failures?
    ].any?

    !critical_failures && meet_safety_thresholds?
  end

  def meet_safety_thresholds?
    height_ok = user_height_assessment&.meets_height_requirements? != false
    runout_ok = slide_assessment&.meets_runout_requirements? != false
    anchor_ok = anchorage_assessment&.meets_anchor_requirements? != false

    height_ok && runout_ok && anchor_ok
  end

  def total_pass_columns
    all_assessments.compact.sum(&:pass_columns_count)
  end

  def passed_safety_checks
    all_assessments.compact.sum(&:passed_checks_count)
  end

  def failed_safety_checks = total_pass_columns - passed_safety_checks

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
