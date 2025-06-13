class MaterialsAssessmentsController < ApplicationController
  include AssessmentController

  private

  def assessment_params
    params.require(:assessments_materials_assessment).permit(
      # Rope specifications
      :ropes, :ropes_pass, :ropes_comment,
      # Critical materials
      :fabric_strength_pass, :fabric_strength_comment,
      :fire_retardant_pass, :fire_retardant_comment,
      :thread_pass, :thread_comment,
      # Additional materials
      :clamber_netting_pass, :clamber_netting_comment,
      :retention_netting_pass, :retention_netting_comment,
      :zips_pass, :zips_comment,
      :windows_pass, :windows_comment,
      :artwork_pass, :artwork_comment
    )
  end
end
