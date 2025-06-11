# RPII Utility - Materials Assessment model
class MaterialsAssessment < ApplicationRecord
  belongs_to :inspection

  # Material specifications
  validates :rope_size,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # Pass/fail assessments for all materials
  MATERIAL_CHECKS = %w[
    artwork_pass
    clamber_pass
    fabric_pass
    fire_retardant_pass
    retention_netting_pass
    rope_size_pass
    thread_pass
    windows_pass
    zips_pass
  ].freeze

  # Critical material checks
  CRITICAL_MATERIAL_CHECKS = %w[
    fabric_pass fire_retardant_pass thread_pass
  ].freeze

  # Derived constants
  SAFETY_CHECK_COUNT = MATERIAL_CHECKS.length

  MATERIAL_CHECKS.each do |check|
    validates check.to_sym, inclusion: {in: [true, false]}, allow_nil: true
  end

  # Callbacks
  after_update :log_assessment_update, if: :saved_changes?

  def complete?
    material_assessments_complete? && rope_specifications_present?
  end

  def has_critical_failures?
    # Fire retardant, fabric strength, and thread are critical for safety
    CRITICAL_MATERIAL_CHECKS.any? { send(it) == false }
  end

  def passed_checks_count = MATERIAL_CHECKS.count { send(it) == true }

  def completion_percentage
    total_fields = SAFETY_CHECK_COUNT + 1 # Include rope_size
    completed_fields = completed_material_fields.count(&:present?)

    (completed_fields.to_f / total_fields * 100).round(0)
  end

  def material_compliance_summary
    {
      critical_passed: critical_checks_passed_count,
      critical_total: CRITICAL_MATERIAL_CHECKS.length,
      overall_passed: passed_checks_count,
      overall_total: SAFETY_CHECK_COUNT,
      rope_compliant: rope_size_compliant?
    }
  end

  def critical_material_status
    failed_critical = failed_critical_checks

    if failed_critical.empty?
      "All critical materials compliant"
    else
      "Critical failures: #{failed_critical.map(&:humanize).join(", ")}"
    end
  end

  def material_test_requirements
    requirements = []

    if fabric_pass != true
      requirements << I18n.t("materials_assessment.requirements.fabric_tensile")
      requirements << I18n.t("materials_assessment.requirements.fabric_tear")
    end
    if fire_retardant_pass != true
      requirements << I18n.t("materials_assessment.requirements.fire_retardant")
    end
    if thread_pass != true
      requirements << I18n.t("materials_assessment.requirements.thread_tensile")
    end
    unless rope_size_compliant?
      requirements << I18n.t("materials_assessment.requirements.rope_diameter")
    end

    requirements
  end

  def non_critical_issues
    non_critical_checks = MATERIAL_CHECKS - CRITICAL_MATERIAL_CHECKS
    failed_checks = non_critical_checks.select { send(it) == false }

    failed_checks.map(&:humanize)
  end

  private

  def material_assessments_complete? = MATERIAL_CHECKS.all? { !send(it).nil? }

  def rope_specifications_present? = rope_size.present?

  def rope_size_compliant? = SafetyStandard.valid_rope_diameter?(rope_size)

  def completed_material_fields
    MATERIAL_CHECKS.map { send(it) } + [rope_size]
  end

  def critical_checks_passed_count
    CRITICAL_MATERIAL_CHECKS.count { send(it) == true }
  end

  def failed_critical_checks
    CRITICAL_MATERIAL_CHECKS.select { send(it) == false }
  end

  def log_assessment_update
    inspection.log_audit_action("assessment_updated", inspection.user,
      "Materials Assessment updated")
  end
end
