# typed: true
# frozen_string_literal: true

class Assessments::AnchorageAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?

  sig { returns(T::Boolean) }
  def meets_anchor_requirements?
    unless total_anchors &&
        inspection.width &&
        inspection.height &&
        inspection.length
      return false
    end

    total_anchors >= anchorage_result.value
  end

  sig { returns(Integer) }
  def total_anchors
    (num_low_anchors || 0) + (num_high_anchors || 0)
  end

  sig { returns(T.any(Object, NilClass)) }
  def anchorage_result
    @anchor_result ||= EN14960.calculate_anchors(
      length: inspection.length,
      width: inspection.width,
      height: inspection.height
    )
  end

  sig { returns(Integer) }
  def required_anchors
    return 0 if inspection.volume.blank?
    anchorage_result.value
  end

  sig { returns(T::Array[T.untyped]) }
  def anchorage_breakdown
    return [] unless inspection.volume
    anchorage_result.breakdown
  end
end
