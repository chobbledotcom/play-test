class Assessments::AnchorageAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

  validates :num_high_anchors,
    :num_low_anchors,
    numericality: {greater_than_or_equal_to: 0, only_integer: true},
    allow_blank: true

  after_update :log_assessment_update, if: :saved_changes?

  def meets_anchor_requirements?
    unless total_anchors &&
        inspection.width &&
        inspection.height &&
        inspection.length
      return false
    end

    total_anchors >= anchorage_result.value
  end

  def total_anchors
    (num_low_anchors || 0) + (num_high_anchors || 0)
  end

  def anchorage_result
    @anchor_result ||= SafetyStandards::AnchorCalculator.calculate(
      length: inspection.length,
      width: inspection.width,
      height: inspection.height
    )
  end

  def required_anchors
    return 0 if inspection.volume.blank?
    anchorage_result.value
  end

  def anchorage_breakdown
    return [] unless inspection.volume
    anchorage_result.breakdown
  end
end
