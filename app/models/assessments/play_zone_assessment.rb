# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: play_zone_assessments
#
#  access_comment                 :text
#  access_pass                    :boolean
#  age_marking_comment            :text
#  age_marking_pass               :boolean
#  air_juggler_comment            :text
#  air_juggler_pass               :boolean
#  ball_pool_depth                :integer
#  ball_pool_depth_comment        :text
#  ball_pool_depth_pass           :boolean
#  ball_pool_entry_height         :integer
#  ball_pool_entry_height_comment :text
#  ball_pool_entry_height_pass    :boolean
#  ball_pool_gaps_comment         :text
#  ball_pool_gaps_pass            :boolean
#  balls_comment                  :text
#  balls_pass                     :boolean
#  fitted_sheet_comment           :text
#  fitted_sheet_pass              :boolean
#  height_marking_comment         :text
#  height_marking_pass            :boolean
#  sight_line_comment             :text
#  sight_line_pass                :boolean
#  slide_gradient                 :integer
#  slide_gradient_comment         :text
#  slide_gradient_pass            :boolean
#  slide_platform_height          :decimal(8, 2)
#  slide_platform_height_comment  :text
#  slide_platform_height_pass     :boolean
#  suitable_matting_comment       :text
#  suitable_matting_pass          :boolean
#  traffic_flow_comment           :text
#  traffic_flow_pass              :boolean
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  inspection_id                  :string(12)       not null, primary key
#
# Indexes
#
#  play_zone_assessments_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
class Assessments::PlayZoneAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?
end
