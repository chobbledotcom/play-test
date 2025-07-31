class Assessments::SlideAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  enum :clamber_netting_pass, Inspection::PASS_FAIL_NA

  def meets_runout_requirements?
    return false unless runout.present? && slide_platform_height.present?
    EN14960::Calculators::SlideCalculator.meets_runout_requirements?(
      runout, slide_platform_height
    )
  end

  def required_runout_length
    return nil if slide_platform_height.blank?
    EN14960::Calculators::SlideCalculator.calculate_runout_value(
      slide_platform_height
    )
  end

  def runout_compliance_status
    return I18n.t("forms.slide.compliance.not_assessed") if runout.blank?
    if meets_runout_requirements?
      I18n.t("forms.slide.compliance.compliant")
    else
      I18n.t("forms.slide.compliance.non_compliant",
        required: required_runout_length)
    end
  end

  def meets_wall_height_requirements?
    return false unless slide_platform_height.present? &&
      slide_wall_height.present? && !slide_permanent_roof.nil?

    # Get user height from the inspection's user height assessment
    user_height = inspection.user_height_assessment?&.tallest_user_height
    return false if user_height.blank?

    EN14960::Calculators::SlideCalculator.meets_height_requirements?(
      slide_platform_height,
      user_height,
      slide_wall_height,
      slide_permanent_roof
    )
  end
end
