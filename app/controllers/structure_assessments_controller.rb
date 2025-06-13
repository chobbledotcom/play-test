class StructureAssessmentsController < ApplicationController
  include AssessmentController

  private

  def assessment_params
    params.require(:assessments_structure_assessment).permit(
      # Critical safety checks
      :seam_integrity_pass, :seam_integrity_comment,
      :lock_stitch_pass, :lock_stitch_comment,
      :air_loss_pass, :air_loss_comment,
      :straight_walls_pass, :straight_walls_comment,
      :sharp_edges_pass, :sharp_edges_comment,
      :unit_stable_pass, :unit_stable_comment,

      # Measurements
      :stitch_length, :stitch_length_pass, :stitch_length_comment,
      :evacuation_time, :evacuation_time_pass, :evacuation_time_comment,
      :unit_pressure_value, :unit_pressure_pass, :unit_pressure_comment,
      :blower_tube_length, :blower_tube_length_pass, :blower_tube_length_comment,

      # Additional measurements
      :step_size_value, :step_size_pass, :step_size_comment,
      :fall_off_height_value, :fall_off_height_pass, :fall_off_height_comment,
      :trough_depth_value, :trough_width_value, :trough_pass, :trough_comment,

      # Other checks
      :entrapment_pass, :entrapment_comment,
      :markings_pass, :markings_comment,
      :grounding_pass, :grounding_comment
    )
  end
end
