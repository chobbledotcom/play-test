# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: ball_pool_assessments
#
#  age_range_marking_comment      :text
#  age_range_marking_pass         :boolean
#  air_jugglers_compliant_comment :text
#  air_jugglers_compliant_pass    :boolean
#  ball_pool_depth                :integer
#  ball_pool_depth_comment        :text
#  ball_pool_depth_pass           :boolean
#  ball_pool_entry                :integer
#  ball_pool_entry_comment        :text
#  ball_pool_entry_pass           :boolean
#  balls_compliant_comment        :text
#  balls_compliant_pass           :boolean
#  fitted_base_comment            :text
#  fitted_base_pass               :boolean
#  gaps_comment                   :text
#  gaps_pass                      :boolean
#  max_height_markings_comment    :text
#  max_height_markings_pass       :boolean
#  suitable_matting_comment       :text
#  suitable_matting_pass          :boolean
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  inspection_id                  :string(12)       not null, primary key
#
# Indexes
#
#  ball_pool_assessments_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
class Assessments::BallPoolAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?
end
