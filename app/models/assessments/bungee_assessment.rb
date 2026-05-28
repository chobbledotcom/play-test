# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: bungee_assessments
#
#  baton_compliant_comment         :string(1000)
#  baton_compliant_pass            :boolean
#  blower_forward_distance_comment :string(1000)
#  blower_forward_distance_pass    :boolean
#  cord_diametre_min_comment       :string(1000)
#  cord_diametre_min_pass          :boolean
#  cord_length_max_comment         :string(1000)
#  cord_length_max_pass            :boolean
#  harness_width                   :integer
#  harness_width_comment           :string(1000)
#  harness_width_pass              :boolean
#  lane_width_max_comment          :string(1000)
#  lane_width_max_pass             :boolean
#  marking_max_mass_comment        :string(1000)
#  marking_max_mass_pass           :boolean
#  marking_min_height_comment      :string(1000)
#  marking_min_height_pass         :boolean
#  num_of_cords                    :integer
#  pull_strength_comment           :string(1000)
#  pull_strength_pass              :boolean
#  rear_wall_comment               :string(1000)
#  rear_wall_height                :decimal(8, 2)
#  rear_wall_height_comment        :string(1000)
#  rear_wall_pass                  :boolean
#  rear_wall_thickness             :decimal(8, 2)
#  rear_wall_thickness_comment     :string(1000)
#  running_wall_comment            :string(1000)
#  running_wall_height             :decimal(8, 2)
#  running_wall_height_comment     :string(1000)
#  running_wall_pass               :boolean
#  running_wall_width              :decimal(8, 2)
#  running_wall_width_comment      :string(1000)
#  side_wall_comment               :string(1000)
#  side_wall_height                :decimal(8, 2)
#  side_wall_height_comment        :string(1000)
#  side_wall_length                :decimal(8, 2)
#  side_wall_length_comment        :string(1000)
#  side_wall_pass                  :boolean
#  two_stage_locking_comment       :string(1000)
#  two_stage_locking_pass          :boolean
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  inspection_id                   :string           not null, primary key
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
class Assessments::BungeeAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?
end
