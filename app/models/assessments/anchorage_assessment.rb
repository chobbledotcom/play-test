class Assessments::AnchorageAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  self.primary_key = "inspection_id"
  belongs_to :inspection

  validates :num_high_anchors,
    :num_low_anchors,
    numericality: {greater_than_or_equal_to: 0, only_integer: true},
    allow_blank: true

  after_update :log_assessment_update, if: :saved_changes?

  def meets_anchor_requirements?
    return false unless total_anchors.present? && inspection.area.present?
    inspection_area = inspection.area
    required_anchors = SafetyStandard.calculate_required_anchors(
      inspection_area
    )
    total_anchors >= required_anchors
  end

  def total_anchors
    (num_low_anchors || 0) + (num_high_anchors || 0)
  end

  def required_anchors
    return 0 unless inspection.area.present?
    SafetyStandard.calculate_required_anchors(inspection.area)
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

  def anchor_counts_present?
    num_low_anchors.present? && num_high_anchors.present?
  end
end
