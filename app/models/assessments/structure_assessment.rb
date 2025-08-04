# typed: true
# frozen_string_literal: true

class Assessments::StructureAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?

  sig { returns(T::Boolean) }
  def meets_height_requirements?
    user_height = inspection.user_height_assessment
    return false unless platform_height.present? &&
      user_height&.tallest_user_height.present? &&
      user_height&.containing_wall_height.present?

    permanent_roof = permanent_roof_status
    return false if permanent_roof.nil?

    EN14960::Calculators::SlideCalculator.meets_height_requirements?(
      platform_height / 1000.0, # Convert mm to m
      user_height.tallest_user_height,
      user_height.containing_wall_height,
      permanent_roof
    )
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
