class FanAssessmentsController < ApplicationController
  include AssessmentController

  private

  def assessment_params
    params.require(:assessments_fan_assessment).permit(
      :blower_serial,
      :fan_size_type,
      :blower_flap_pass,
      :blower_flap_comment,
      :blower_finger_pass,
      :blower_finger_comment,
      :blower_visual_pass,
      :blower_visual_comment,
      :pat_pass,
      :pat_comment
    )
  end
end