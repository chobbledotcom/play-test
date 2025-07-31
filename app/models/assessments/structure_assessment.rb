class Assessments::StructureAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :unit_pressure,
    :step_ramp_size,
    :trough_depth,
    :trough_adjacent_panel_width,
    numericality: {greater_than_or_equal_to: 0},
    allow_blank: true

  validates :platform_height,
    :critical_fall_off_height,
    numericality: {greater_than_or_equal_to: 10},
    allow_blank: true

  after_update :log_assessment_update, if: :saved_changes?

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

  def permanent_roof_status
    # Permanent roof only matters for platforms 3000mm and above
    return false if platform_height < 3000

    # For platforms 3.0m+, check slide assessment if inspection has a slide
    return false unless inspection.has_slide?

    inspection.slide_assessment&.slide_permanent_roof
  end
end
