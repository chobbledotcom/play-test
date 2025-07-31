class Assessments::AnchorageAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

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
    @anchor_result ||= EN14960.calculate_anchors(
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
