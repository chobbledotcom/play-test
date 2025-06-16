class Assessments::SlideAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  belongs_to :inspection

  validates :slide_platform_height,
    :slide_wall_height,
    :runout,
    :slide_first_metre_height,
    :slide_beyond_first_metre_height,
    numericality: {greater_than_or_equal_to: 0},
    allow_blank: true

  def meets_runout_requirements?
    return false unless runout.present? && slide_platform_height.present?
    SafetyStandard.meets_runout_requirements?(runout, slide_platform_height)
  end

  def required_runout_length
    return nil unless slide_platform_height.present?
    SafetyStandard.calculate_required_runout(slide_platform_height)
  end

  def runout_compliance_status
    return "Not Assessed" unless runout.present?
    if meets_runout_requirements?
      "Compliant"
    else
      "Non-Compliant (Requires #{required_runout_length}m minimum)"
    end
  end
end
