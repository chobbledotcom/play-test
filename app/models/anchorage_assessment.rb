# RPII Utility - Anchorage Assessment model
class AnchorageAssessment < ApplicationRecord
  belongs_to :inspection

  # Anchor counts (alphabetical order)
  validates :num_high_anchors, :num_low_anchors,
    numericality: {greater_than_or_equal_to: 0, only_integer: true},
    allow_blank: true

  # Pass/fail assessments
  validates :num_anchors_pass, :anchor_accessories_pass, :anchor_degree_pass,
    :anchor_type_pass, :pull_strength_pass,
    inclusion: {in: [true, false]}, allow_nil: true

  # Callbacks
  after_update :log_assessment_update, if: :saved_changes?
  after_save :update_anchor_calculations, if: :saved_change_to_anchor_counts?

  def complete?
    anchor_counts_present? && anchor_assessments_complete?
  end

  def meets_anchor_requirements?
    return false unless total_anchors.present? && inspection.unit.area.present?

    unit_area = inspection.unit.area
    required_anchors = SafetyStandard.calculate_required_anchors(unit_area)
    total_anchors >= required_anchors
  end

  def has_critical_failures?
    [anchor_type_pass, pull_strength_pass].any? { |check| check == false }
  end

  def total_anchors
    (num_low_anchors || 0) + (num_high_anchors || 0)
  end

  def required_anchors
    return 0 unless inspection.unit.area.present?
    SafetyStandard.calculate_required_anchors(inspection.unit.area)
  end

  def anchor_compliance_status
    return "Not Assessed" unless total_anchors.present?

    if meets_anchor_requirements?
      "Compliant"
    else
      required = required_anchors
      actual = total_anchors
      "Non-Compliant (Requires #{required} total anchors, has #{actual})"
    end
  end

  def safety_check_count
    5 # All anchor-related pass/fail checks
  end

  def passed_checks_count
    [num_anchors_pass, anchor_accessories_pass, anchor_degree_pass,
      anchor_type_pass, pull_strength_pass].count(true)
  end

  def completion_percentage
    total_fields = 7 # Total assessable fields
    completed_fields = [
      num_low_anchors, num_high_anchors,
      num_anchors_pass, anchor_accessories_pass, anchor_degree_pass,
      anchor_type_pass, pull_strength_pass
    ].count { |field| !field.nil? }

    (completed_fields.to_f / total_fields * 100).round(0)
  end

  def anchor_distribution
    return {} unless num_low_anchors.present? && num_high_anchors.present?

    {
      low_anchors: num_low_anchors,
      high_anchors: num_high_anchors,
      total: total_anchors,
      required: required_anchors,
      percentage_low: (num_low_anchors.to_f / total_anchors * 100).round(1),
      percentage_high: (num_high_anchors.to_f / total_anchors * 100).round(1)
    }
  end

  def anchor_safety_summary
    issues = []

    issues << "Insufficient total anchors" unless meets_anchor_requirements?
    issues << "Anchor type non-compliant" if anchor_type_pass == false
    issues << "Pull strength insufficient" if pull_strength_pass == false
    issues << "Anchor angle incorrect" if anchor_degree_pass == false
    issues << "Missing anchor accessories" if anchor_accessories_pass == false

    issues.empty? ? "All anchor requirements met" : issues.join(", ")
  end

  private

  def anchor_counts_present?
    num_low_anchors.present? && num_high_anchors.present?
  end

  def anchor_assessments_complete?
    [num_anchors_pass, anchor_accessories_pass, anchor_degree_pass,
      anchor_type_pass, pull_strength_pass].none?(&:nil?)
  end

  def saved_change_to_anchor_counts?
    saved_change_to_num_low_anchors? || saved_change_to_num_high_anchors?
  end

  def update_anchor_calculations
    # Auto-update num_anchors_pass based on calculations
    if anchor_counts_present? && inspection.unit.area.present?
      update_column(:num_anchors_pass, meets_anchor_requirements?)
    end
  end

  def log_assessment_update
    inspection.log_audit_action("assessment_updated",
      inspection.user,
      "Anchorage Assessment updated")
  end
end
