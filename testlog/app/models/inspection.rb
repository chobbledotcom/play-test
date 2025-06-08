class Inspection < ApplicationRecord
  include CustomIdGenerator
  include HasDimensions

  belongs_to :user
  belongs_to :unit, optional: true
  belongs_to :inspector_company

  # Assessment associations (normalized from single table)
  has_one :user_height_assessment, class_name: "UserHeightAssessment", dependent: :destroy
  has_one :slide_assessment, class_name: "SlideAssessment", dependent: :destroy
  has_one :structure_assessment, class_name: "StructureAssessment", dependent: :destroy
  has_one :anchorage_assessment, class_name: "AnchorageAssessment", dependent: :destroy
  has_one :materials_assessment, class_name: "MaterialsAssessment", dependent: :destroy
  has_one :fan_assessment, class_name: "FanAssessment", dependent: :destroy
  has_one :enclosed_assessment, class_name: "EnclosedAssessment", dependent: :destroy

  # Accept nested attributes for all assessments
  accepts_nested_attributes_for :user_height_assessment, :slide_assessment,
    :structure_assessment, :anchorage_assessment,
    :materials_assessment, :fan_assessment,
    :enclosed_assessment

  # Validations - allow drafts to be incomplete
  validates :inspection_location, presence: true, unless: -> { status == "draft" }
  validates :inspection_date, presence: true
  validates :unique_report_number, presence: true, uniqueness: {scope: :user_id}, if: -> { status.present? && status != "draft" }

  # Status validations
  validates :status, inclusion: {in: %w[draft complete]}, allow_blank: true

  # Callbacks
  before_validation :set_inspector_company_from_user, on: :create
  before_validation :copy_unit_values, on: :create, if: :unit_id_changed?
  before_create :generate_unique_report_number, if: -> { status.present? && status != "draft" }
  before_create :copy_unit_values
  before_save :auto_determine_pass_fail, if: :all_assessments_complete?
  # Removed automatic assessment creation - assessments should be created explicitly when needed
  after_update :log_status_change, if: :saved_change_to_status?

  # Scopes
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :complete, -> { where(status: "complete") }
  scope :draft, -> { where(status: "draft") }
  scope :search, ->(query) {
    if query.present?
      joins("LEFT JOIN units ON units.id = inspections.unit_id")
        .where("inspections.inspection_location LIKE ? OR inspections.id LIKE ? OR inspections.unique_report_number LIKE ? OR units.serial LIKE ? OR units.manufacturer LIKE ? OR units.name LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
    else
      all
    end
  }
  scope :filter_by_status, ->(status) { where(status: status) if status.present? }
  scope :filter_by_result, ->(result) {
    case result
    when "passed" then where(passed: true)
    when "failed" then where(passed: false)
    end
  }
  scope :filter_by_unit, ->(unit_id) { where(unit_id: unit_id) if unit_id.present? }
  scope :filter_by_date_range, ->(start_date, end_date) { where(inspection_date: start_date..end_date) if start_date.present? && end_date.present? }
  scope :overdue, -> { where("inspection_date < ?", Date.today - 1.year) }

  # State machine for inspection workflow
  enum :status, {
    draft: "draft",
    complete: "complete"
  }, prefix: true

  # Delegate methods to unit
  delegate :name, :serial, :manufacturer, to: :unit, allow_nil: true

  # Calculated fields
  def reinspection_date
    return nil unless inspection_date.present?
    inspection_date + 1.year
  end

  # URL routing based on status
  def primary_url_path
    case status
    when "complete"
      "inspection_path(self)"
    when "draft"
      "edit_inspection_path(self)"
    else
      raise "Invalid inspection status: #{status}"
    end
  end

  # Advanced methods
  def can_be_completed?
    unit.present? && all_assessments_complete?
  end

  def completion_status
    {
      status: status,
      all_assessments_complete: all_assessments_complete?,
      missing_assessments: get_missing_assessments,
      can_be_completed: can_be_completed?
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
    missing << "Enclosed" if is_totally_enclosed? && !enclosed_assessment&.complete?
    missing
  end

  def complete!(user)
    update!(status: "complete")
    log_audit_action("completed", user, "Inspection completed")
  end

  def duplicate_for_user(user)
    new_inspection = dup
    new_inspection.user = user
    new_inspection.status = "draft"
    new_inspection.unique_report_number = nil
    new_inspection.passed = nil
    new_inspection.save!

    # Duplicate all assessments
    duplicate_assessments(new_inspection)

    new_inspection
  end

  def validate_completeness
    errors = []

    # Check each assessment section if they exist
    errors << "User Height Assessment incomplete" if user_height_assessment.present? && !user_height_assessment.complete?
    errors << "Slide Assessment incomplete" if slide_assessment.present? && !slide_assessment.complete?
    errors << "Structure Assessment incomplete" if structure_assessment.present? && !structure_assessment.complete?
    errors << "Anchorage Assessment incomplete" if anchorage_assessment.present? && !anchorage_assessment.complete?
    errors << "Materials Assessment incomplete" if materials_assessment.present? && !materials_assessment.complete?
    errors << "Fan Assessment incomplete" if fan_assessment.present? && !fan_assessment.complete?
    errors << "Totally Enclosed Assessment incomplete" if enclosed_assessment.present? && !enclosed_assessment.complete?

    errors
  end

  def pass_fail_summary
    return {total_checks: 0, passed_checks: 0, failed_checks: 0, pass_percentage: 0} if total_safety_checks == 0

    {
      total_checks: total_safety_checks,
      passed_checks: passed_safety_checks,
      failed_checks: failed_safety_checks,
      pass_percentage: (passed_safety_checks.to_f / total_safety_checks * 100).round(2)
    }
  end

  def log_audit_action(action, user, details)
    # Simple logging for now - could be enhanced with audit log table later
    Rails.logger.info("Inspection #{id}: #{action} by #{user&.email} - #{details}")
  end

  private

  def generate_unique_report_number
    return if unique_report_number.present?
    self.unique_report_number = "RPII-#{Date.current.strftime("%Y%m%d")}-#{SecureRandom.hex(4).upcase}"
  end

  def copy_unit_values
    return unless unit.present?

    # Copy all dimensions and boolean flags from unit using the concern method
    copy_dimensions_from(unit)
  end

  def set_inspector_company_from_user
    self.inspector_company_id ||= user.inspection_company_id
  end

  def create_assessment_records
    create_user_height_assessment! unless user_height_assessment.present?
    create_slide_assessment! unless slide_assessment.present?
    create_structure_assessment! unless structure_assessment.present?
    create_anchorage_assessment! unless anchorage_assessment.present?
    create_materials_assessment! unless materials_assessment.present?
    create_fan_assessment! unless fan_assessment.present?
    create_enclosed_assessment! if is_totally_enclosed? && !enclosed_assessment.present?

    log_audit_action("created", user, "Inspection created with assessment records") if respond_to?(:log_audit_action)
  end

  def all_assessments_complete?
    return false unless has_assessments?

    required_assessments = [
      user_height_assessment&.complete?,
      structure_assessment&.complete?,
      anchorage_assessment&.complete?,
      materials_assessment&.complete?,
      fan_assessment&.complete?
    ]

    # Add slide assessment if inspection has a slide
    if has_slide?
      required_assessments << slide_assessment&.complete?
    end

    # Add enclosed assessment if required
    if is_totally_enclosed?
      required_assessments << enclosed_assessment&.complete?
    end

    required_assessments.all?
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
      structure_assessment&.respond_to?(:has_critical_failures?) && structure_assessment.has_critical_failures?,
      anchorage_assessment&.respond_to?(:has_critical_failures?) && anchorage_assessment.has_critical_failures?,
      materials_assessment&.respond_to?(:has_critical_failures?) && materials_assessment.has_critical_failures?
    ].any?

    !critical_failures && meet_safety_thresholds?
  end

  def meet_safety_thresholds?
    return true unless has_assessments?

    height_ok = !user_height_assessment&.respond_to?(:meets_height_requirements?) || user_height_assessment&.meets_height_requirements?
    runout_ok = !slide_assessment&.respond_to?(:meets_runout_requirements?) || slide_assessment&.meets_runout_requirements?
    anchor_ok = !anchorage_assessment&.respond_to?(:meets_anchor_requirements?) || anchorage_assessment&.meets_anchor_requirements?

    height_ok && runout_ok && anchor_ok
  end

  def total_safety_checks
    return 0 unless has_assessments?

    assessments = [user_height_assessment, slide_assessment, structure_assessment,
      anchorage_assessment, materials_assessment, fan_assessment]
    assessments << enclosed_assessment if is_totally_enclosed?

    assessments.compact.sum { |a| a.respond_to?(:safety_check_count) ? a.safety_check_count : 0 }
  end

  def passed_safety_checks
    return 0 unless has_assessments?

    assessments = [user_height_assessment, slide_assessment, structure_assessment,
      anchorage_assessment, materials_assessment, fan_assessment]
    assessments << enclosed_assessment if is_totally_enclosed?

    assessments.compact.sum { |a| a.respond_to?(:passed_checks_count) ? a.passed_checks_count : 0 }
  end

  def failed_safety_checks
    total_safety_checks - passed_safety_checks
  end

  def duplicate_assessments(new_inspection)
    user_height_assessment&.dup&.tap { |a|
      a.inspection = new_inspection
      a.save!
    }
    slide_assessment&.dup&.tap { |a|
      a.inspection = new_inspection
      a.save!
    }
    structure_assessment&.dup&.tap { |a|
      a.inspection = new_inspection
      a.save!
    }
    anchorage_assessment&.dup&.tap { |a|
      a.inspection = new_inspection
      a.save!
    }
    materials_assessment&.dup&.tap { |a|
      a.inspection = new_inspection
      a.save!
    }
    fan_assessment&.dup&.tap { |a|
      a.inspection = new_inspection
      a.save!
    }
    if is_totally_enclosed?
      enclosed_assessment&.dup&.tap { |a|
        a.inspection = new_inspection
        a.save!
      }
    end
  end

  def log_status_change
    log_audit_action("status_changed", user, "Status changed from #{status_before_last_save} to #{status}")
  end
end
