class EnclosedAssessmentsController < ApplicationController
  include AssessmentController

  private

  def assessment_params
    params.require(:assessments_enclosed_assessment).permit(
      :exit_number,
      :exit_number_pass,
      :exit_number_comment,
      :exit_sign_always_visible_pass,
      :exit_sign_always_visible_comment,
      :exit_sign_visible_pass
    )
  end
end
