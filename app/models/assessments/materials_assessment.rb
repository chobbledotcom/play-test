class Assessments::MaterialsAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  belongs_to :inspection

  # Material specifications
  validates :ropes,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # Pass/fail assessments for all materials
  MATERIAL_CHECKS = %w[
    artwork_pass
    clamber_netting_pass
    fabric_strength_pass
    fire_retardant_pass
    retention_netting_pass
    ropes_pass
    thread_pass
    windows_pass
    zips_pass
  ].freeze

  # Critical material checks
  CRITICAL_MATERIAL_CHECKS = %w[
    fabric_strength_pass fire_retardant_pass thread_pass
  ].freeze

  # Validate all material checks - includes the fields moved from inspections:
  # retention_netting_pass, zips_pass, windows_pass, artwork_pass
  MATERIAL_CHECKS.each do |check|
    validates check.to_sym, inclusion: {in: [true, false]}, allow_nil: true
  end

  # Callbacks
  after_update :log_assessment_update, if: :saved_changes?

  def has_critical_failures?
    # Fire retardant, fabric strength, and thread are critical for safety
    CRITICAL_MATERIAL_CHECKS.any? { send(it) == false }
  end

  def material_compliance_summary
    {
      critical_passed: critical_checks_passed_count,
      critical_total: CRITICAL_MATERIAL_CHECKS.length,
      overall_passed: passed_checks_count,
      overall_total: pass_columns_count,
      rope_compliant: ropes_compliant?
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

    if fabric_strength_pass != true
      requirements << I18n.t("materials_assessment.requirements.fabric_tensile")
      requirements << I18n.t("materials_assessment.requirements.fabric_tear")
    end
    if fire_retardant_pass != true
      requirements << I18n.t("materials_assessment.requirements.fire_retardant")
    end
    if thread_pass != true
      requirements << I18n.t("materials_assessment.requirements.thread_tensile")
    end
    unless ropes_compliant?
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

  def ropes_compliant? = SafetyStandard.valid_rope_diameter?(ropes)

  def completed_material_fields
    MATERIAL_CHECKS.map { send(it) } + [ropes]
  end

  def critical_checks_passed_count
    CRITICAL_MATERIAL_CHECKS.count { send(it) == true }
  end

  def failed_critical_checks
    CRITICAL_MATERIAL_CHECKS.select { send(it) == false }
  end
end
