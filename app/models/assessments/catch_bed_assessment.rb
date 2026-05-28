# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: catch_bed_assessments
#
#  ancillary_compliant_comment    :text
#  ancillary_compliant_pass       :boolean
#  ancillary_fit_comment          :text
#  ancillary_fit_pass             :boolean
#  apron_comment                  :text
#  apron_pass                     :boolean
#  arrest_comment                 :text
#  arrest_pass                    :boolean
#  bed_height                     :integer
#  bed_height_comment             :text
#  bed_height_pass                :boolean
#  blower_tube_length             :decimal(8, 2)
#  blower_tube_length_comment     :text
#  blower_tube_length_pass        :boolean
#  design_risk_comment            :text
#  design_risk_pass               :boolean
#  framework_comment              :text
#  framework_pass                 :boolean
#  grounding_comment              :text
#  grounding_pass                 :boolean
#  intended_play_comment          :text
#  intended_play_pass             :boolean
#  matting_comment                :text
#  matting_pass                   :boolean
#  max_user_mass_marking_comment  :text
#  max_user_mass_marking_pass     :boolean
#  platform_fall_distance         :decimal(8, 2)
#  platform_fall_distance_comment :text
#  platform_fall_distance_pass    :boolean
#  trough_comment                 :text
#  trough_pass                    :boolean
#  type_of_unit                   :text
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  inspection_id                  :string(12)       not null, primary key
#
# Indexes
#
#  catch_bed_assessments_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
class Assessments::CatchBedAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"
  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?
end
