# == Schema Information
#
# Table name: anchorage_assessments
#
#  id                         :integer          not null
#  inspection_id              :string(8)        not null, primary key
#  num_low_anchors            :integer
#  num_high_anchors           :integer
#  anchor_accessories_pass    :boolean
#  anchor_degree_pass         :boolean
#  anchor_type_pass           :boolean
#  pull_strength_pass         :boolean
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  anchor_accessories_comment :text
#  anchor_degree_comment      :text
#  anchor_type_comment        :text
#  pull_strength_comment      :text
#  num_low_anchors_comment    :text
#  num_high_anchors_comment   :text
#  num_low_anchors_pass       :boolean
#  num_high_anchors_pass      :boolean
#
# Indexes
#
#  index_anchorage_assessments_on_inspection_id  (inspection_id)
#

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
