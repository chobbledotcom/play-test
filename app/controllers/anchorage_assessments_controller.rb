class AnchorageAssessmentsController < ApplicationController
  include AssessmentController

  private

  def assessment_params
    params.require(:assessments_anchorage_assessment).permit(
      :num_low_anchors,
      :num_high_anchors,
      :num_anchors_pass,
      :anchor_accessories_pass,
      :anchor_degree_pass,
      :anchor_type_pass,
      :pull_strength_pass,
      :num_anchors_comment,
      :anchor_accessories_comment,
      :anchor_degree_comment,
      :anchor_type_comment,
      :pull_strength_comment
    )
  end
end
