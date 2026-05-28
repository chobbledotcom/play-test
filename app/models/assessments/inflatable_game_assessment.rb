# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: inflatable_game_assessments
#
#  age_range_marking_comment             :text
#  age_range_marking_pass                :boolean
#  ancillary_equipment_comment           :text
#  ancillary_equipment_compliant_comment :text
#  ancillary_equipment_compliant_pass    :boolean
#  ancillary_equipment_pass              :boolean
#  constant_air_flow_comment             :text
#  constant_air_flow_pass                :boolean
#  containing_wall_height                :decimal(8, 2)
#  containing_wall_height_comment        :text
#  containing_wall_height_pass           :boolean
#  design_risk_comment                   :text
#  design_risk_pass                      :boolean
#  game_type                             :text
#  intended_play_risk_comment            :text
#  intended_play_risk_pass               :boolean
#  max_user_mass_comment                 :text
#  max_user_mass_pass                    :boolean
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  inspection_id                         :string(12)       not null, primary key
#
# Indexes
#
#  inflatable_game_assessments_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
class Assessments::InflatableGameAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?
end
