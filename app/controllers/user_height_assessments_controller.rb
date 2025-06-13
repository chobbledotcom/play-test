class UserHeightAssessmentsController < ApplicationController
  include AssessmentController

  private

  def assessment_params
    params.require(:assessments_user_height_assessment).permit(
      # Wall heights
      :containing_wall_height, :containing_wall_height_comment,
      :secondary_wall_height, :secondary_wall_height_comment,
      :platform_height, :platform_height_comment,

      # Pass/fail checks
      :containing_wall_height_pass, :secondary_wall_height_pass,
      :platform_height_pass,

      # User counts
      :users_at_1000mm, :users_at_1200mm,
      :users_at_1500mm, :users_at_1800mm,

      # Play area
      :play_area_length, :play_area_length_comment,
      :play_area_width, :play_area_width_comment,
      :negative_adjustment, :negative_adjustment_comment,

      # Other
      :tallest_user_height, :tallest_user_height_comment,
      :permanent_roof
    )
  end
end
