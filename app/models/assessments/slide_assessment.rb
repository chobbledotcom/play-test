class Assessments::SlideAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  self.primary_key = "inspection_id"

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
    SafetyStandards::SlideCalculator.meets_runout_requirements?(runout, slide_platform_height)
  end

  def required_runout_length
    return nil if slide_platform_height.blank?
    SafetyStandards::SlideCalculator.calculate_runout_value(slide_platform_height)
  end

  def runout_compliance_status
    return I18n.t("forms.slide.compliance.not_assessed") if runout.blank?
    if meets_runout_requirements?
      I18n.t("forms.slide.compliance.compliant")
    else
      I18n.t("forms.slide.compliance.non_compliant", required: required_runout_length)
    end
  end
end
