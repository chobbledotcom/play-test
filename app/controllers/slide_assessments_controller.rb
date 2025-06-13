class SlideAssessmentsController < ApplicationController
  include AssessmentController
  
  private

  def assessment_params
    params.require(:assessments_slide_assessment).permit(
      # Primary dimensions
      :slide_platform_height, :slide_platform_height_comment,
      :slide_wall_height, :slide_wall_height_comment,
      :slide_length, :slide_length_comment,
      :slide_angle, :slide_angle_comment,
      
      # Slide features
      :slide_extension, :slide_extension_comment,
      :slide_lip, :slide_lip_comment,
      :side_protection_height, :side_protection_height_comment,
      
      # Critical checks
      :side_protection_continuous_pass, :side_protection_continuous_comment,
      :slip_sheet_pass, :slip_sheet_comment,
      :slide_cover_pass, :slide_cover_comment,
      :slide_surround_pass, :slide_surround_comment,
      :clamber_netting_pass, :clamber_netting_comment,
      
      # Runout measurements
      :runout, :runout_comment,
      :total_height_for_runout, :total_height_for_runout_comment,
      
      # Permanent roof
      :permanent_roof_pass, :permanent_roof_comment
    )
  end
end