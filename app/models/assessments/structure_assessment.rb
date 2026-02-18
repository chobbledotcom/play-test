# == Schema Information
#
# Table name: structure_assessments
#
#  air_loss_comment                    :text
#  air_loss_pass                       :boolean
#  critical_fall_off_height            :integer
#  critical_fall_off_height_comment    :text
#  critical_fall_off_height_pass       :boolean
#  entrapment_comment                  :text
#  entrapment_pass                     :boolean
#  evacuation_time_comment             :text
#  evacuation_time_pass                :boolean
#  grounding_comment                   :text
#  grounding_pass                      :boolean
#  markings_comment                    :text
#  markings_pass                       :boolean
#  platform_height                     :integer
#  platform_height_comment             :text
#  platform_height_pass                :boolean
#  seam_integrity_comment              :text
#  seam_integrity_pass                 :boolean
#  sharp_edges_comment                 :text
#  sharp_edges_pass                    :boolean
#  step_ramp_size                      :integer
#  step_ramp_size_comment              :text
#  step_ramp_size_pass                 :boolean
#  stitch_length_comment               :text
#  stitch_length_pass                  :boolean
#  straight_walls_comment              :text
#  straight_walls_pass                 :boolean
#  trough_adjacent_panel_width         :integer
#  trough_adjacent_panel_width_comment :text
#  trough_comment                      :text
#  trough_depth                        :integer
#  trough_depth_comment                :string(1000)
#  trough_pass                         :boolean
#  unit_pressure                       :decimal(8, 2)
#  unit_pressure_comment               :text
#  unit_pressure_pass                  :boolean
#  unit_stable_comment                 :text
#  unit_stable_pass                    :boolean
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  inspection_id                       :string(12)       not null, primary key
#
# Indexes
#
#  structure_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

# typed: true
# frozen_string_literal: true

class Assessments::StructureAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include ColumnNameSyms
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?

  sig { returns(T::Boolean) }
  def meets_height_requirements?
    user_height = inspection.user_height_assessment
    return false unless platform_height.present? &&
      user_height&.containing_wall_height.present?

    permanent_roof = permanent_roof_status
    return false if permanent_roof.nil?

    # Check if height requirements are met for all preset user heights
    [1.0, 1.2, 1.5, 1.8].all? do |height|
      EN14960::Calculators::SlideCalculator.meets_height_requirements?(
        platform_height / 1000.0, # Convert mm to m
        height,
        user_height.containing_wall_height.to_f,
        permanent_roof
      )
    end
  end

  private

  sig { returns(T::Boolean) }
  def permanent_roof_status
    # Permanent roof only matters for platforms 3000mm and above
    return false if platform_height < 3000

    # For platforms 3.0m+, check slide assessment if inspection has a slide
    return false unless inspection.has_slide?

    inspection.slide_assessment&.slide_permanent_roof
  end
end
