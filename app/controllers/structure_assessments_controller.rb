class StructureAssessmentsController < ApplicationController
  include AssessmentController

  private

  def assessment_params
    params.require(:assessments_structure_assessment).permit(
      # Critical safety checks
      :seam_integrity_pass, :seam_integrity_comment,
      :uses_lock_stitching_pass, :uses_lock_stitching_comment,
      :air_loss_pass, :air_loss_comment,
      :straight_walls_pass, :straight_walls_comment,
      :sharp_edges_pass, :sharp_edges_comment,
      :unit_stable_pass, :unit_stable_comment,
      # Measurements
      :stitch_length, :stitch_length_pass, :stitch_length_comment,
      :evacuation_time, :evacuation_time_pass, :evacuation_time_comment,
      :unit_pressure, :unit_pressure_pass, :unit_pressure_comment,
      :blower_tube_length, :blower_tube_length_pass, :blower_tube_length_comment,
      # Additional measurements
      :step_ramp_size, :step_ramp_size_pass, :step_ramp_size_comment,
      :critical_fall_off_height, :critical_fall_off_height_pass, :critical_fall_off_height_comment,
      :trough_depth, :trough_pass, :trough_comment,
      # Additional trough fields
      :trough_depth_pass, :trough_depth_comment,
      :trough_adjacent_panel_width, :trough_adjacent_panel_width_pass, :trough_adjacent_panel_width_comment,
      # Other checks
      :entrapment_pass, :entrapment_comment,
      :markings_pass, :markings_comment,
      :grounding_pass, :grounding_comment
    )
  end
end
