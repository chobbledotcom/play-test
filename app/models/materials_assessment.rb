# RPII Utility - Materials Assessment model
class MaterialsAssessment < ApplicationRecord
  belongs_to :inspection

  # Material specifications
  validates :rope_size, numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # Pass/fail assessments for all materials
  MATERIAL_CHECKS = %w[rope_size_pass clamber_pass retention_netting_pass
    zips_pass windows_pass artwork_pass thread_pass
    fabric_pass fire_retardant_pass].freeze

  # Critical material checks
  CRITICAL_MATERIAL_CHECKS = %w[fabric_pass fire_retardant_pass thread_pass].freeze

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
    CRITICAL_MATERIAL_CHECKS.any? { |check| send(check) == false }
  end

  def safety_check_count
    MATERIAL_CHECKS.length
  end

  def passed_checks_count
    MATERIAL_CHECKS.count { |check| send(check) == true }
  end

  def completion_percentage
    total_fields = MATERIAL_CHECKS.length + 1 # Include rope_size
    completed_fields = (MATERIAL_CHECKS.map { |check| send(check) } + [rope_size]).count(&:present?)

    (completed_fields.to_f / total_fields * 100).round(0)
  end

  def material_compliance_summary
    {
      critical_passed: CRITICAL_MATERIAL_CHECKS.count { |check| send(check) == true },
      critical_total: CRITICAL_MATERIAL_CHECKS.length,
      overall_passed: passed_checks_count,
      overall_total: safety_check_count,
      rope_compliant: rope_size_compliant?
    }
  end

  def critical_material_status
    failed_critical = CRITICAL_MATERIAL_CHECKS.select { |check| send(check) == false }

    if failed_critical.empty?
      "All critical materials compliant"
    else
      "Critical failures: #{failed_critical.map(&:humanize).join(", ")}"
    end
  end

  def material_test_requirements
    requirements = []

    requirements << "Fabric tensile strength: 1850N minimum" if fabric_pass != true
    requirements << "Fabric tear strength: 350N minimum" if fabric_pass != true
    requirements << "Fire retardancy: EN 71-3 compliance" if fire_retardant_pass != true
    requirements << "Thread tensile strength: 88N minimum" if thread_pass != true
    requirements << "Rope diameter: 18-45mm range" unless rope_size_compliant?

    requirements
  end

  def non_critical_issues
    non_critical_checks = MATERIAL_CHECKS - CRITICAL_MATERIAL_CHECKS
    failed_checks = non_critical_checks.select { |check| send(check) == false }

    failed_checks.map(&:humanize)
  end

  private

  def material_assessments_complete?
    MATERIAL_CHECKS.all? { |check| !send(check).nil? }
  end

  def rope_specifications_present?
    rope_size.present?
  end

  def rope_size_compliant?
    SafetyStandard.valid_rope_diameter?(rope_size)
  end

  def log_assessment_update
    inspection.log_audit_action("assessment_updated", inspection.user, "Materials Assessment updated")
  end
end
