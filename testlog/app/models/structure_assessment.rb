# RPII Utility - Structure Assessment model
class StructureAssessment < ApplicationRecord
  belongs_to :inspection

  # Critical safety checks
  CRITICAL_CHECKS = %w[seam_integrity_pass lock_stitch_pass air_loss_pass
    straight_walls_pass sharp_edges_pass unit_stable_pass].freeze

  # Pass/fail validations
  CRITICAL_CHECKS.each do |check|
    validates check.to_sym, inclusion: {in: [true, false]}, allow_nil: true
  end

  # Additional pass/fail checks
  validates :stitch_length_pass, :blower_tube_length_pass, :evacuation_time_pass,
    :step_size_pass, :fall_off_height_pass, :unit_pressure_pass,
    :trough_pass, :entrapment_pass, :markings_pass, :grounding_pass,
    inclusion: {in: [true, false]}, allow_nil: true

  # Measurements
  validates :stitch_length, :evacuation_time, :unit_pressure_value,
    :blower_tube_length, :step_size_value, :fall_off_height_value,
    :trough_depth_value, :trough_width_value,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # Callbacks
  after_update :log_assessment_update, if: :saved_changes?

  def complete?
    critical_checks_assessed? && measurements_present? && additional_checks_complete?
  end

  def has_critical_failures?
    CRITICAL_CHECKS.any? { |check| send(check) == false }
  end

  def safety_check_count
    CRITICAL_CHECKS.length + 10 # Additional measurement-based checks
  end

  def passed_checks_count
    critical_passes = CRITICAL_CHECKS.count { |check| send(check) == true }
    additional_passes = [
      stitch_length_pass, blower_tube_length_pass, evacuation_time_pass,
      step_size_pass, fall_off_height_pass, unit_pressure_pass,
      trough_pass, entrapment_pass, markings_pass, grounding_pass
    ].count(true)

    critical_passes + additional_passes
  end

  def completion_percentage
    total_fields = 20 # Total assessable fields
    completed_fields = (
      CRITICAL_CHECKS.map { |check| send(check) } +
      [stitch_length, evacuation_time, unit_pressure_value, blower_tube_length] +
      [stitch_length_pass, evacuation_time_pass, unit_pressure_pass, blower_tube_length_pass]
    ).count(&:present?)

    (completed_fields.to_f / total_fields * 100).round(0)
  end

  def critical_failure_summary
    failures = CRITICAL_CHECKS.select { |check| send(check) == false }
    return "No critical failures" if failures.empty?

    "Critical failures: #{failures.map(&:humanize).join(", ")}"
  end

  def measurement_compliance
    {
      stitch_length: stitch_length_compliant?,
      evacuation_time: evacuation_time_compliant?,
      unit_pressure: unit_pressure_compliant?,
      blower_tube_distance: blower_tube_distance_compliant?,
      fall_off_height: fall_off_height_compliant?
    }
  end

  private

  def critical_checks_assessed?
    CRITICAL_CHECKS.all? { |check| !send(check).nil? }
  end

  def measurements_present?
    stitch_length.present? && evacuation_time.present? &&
      unit_pressure_value.present? && blower_tube_length.present?
  end

  def additional_checks_complete?
    [stitch_length_pass, evacuation_time_pass, unit_pressure_pass,
      blower_tube_length_pass, step_size_pass, fall_off_height_pass].none?(&:nil?)
  end

  def stitch_length_compliant?
    SafetyStandard.valid_stitch_length?(stitch_length)
  end

  def evacuation_time_compliant?
    SafetyStandard.valid_evacuation_time?(evacuation_time)
  end

  def unit_pressure_compliant?
    SafetyStandard.valid_pressure?(unit_pressure_value)
  end

  def blower_tube_distance_compliant?
    blower_tube_length.present? && blower_tube_length >= 1.2 # 1.2m minimum
  end

  def fall_off_height_compliant?
    SafetyStandard.valid_fall_height?(fall_off_height_value)
  end

  def log_assessment_update
    inspection.log_audit_action("assessment_updated", inspection.user, "Structure Assessment updated")
  end
end
