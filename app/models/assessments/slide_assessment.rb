class Assessments::SlideAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods

  belongs_to :inspection

  # Slide measurements
  validates :slide_platform_height, :slide_wall_height, :runout,
    :slide_first_metre_height, :slide_beyond_first_metre_height,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # Pass/fail assessments
  validates :clamber_netting_pass, :runout_pass, :slip_sheet_pass,
    inclusion: {in: [true, false]}, allow_nil: true

  def complete?
    slide_measurements_present? && safety_assessments_complete?
  end

  def meets_runout_requirements?
    return false unless runout.present? && slide_platform_height.present?

    SafetyStandard.meets_runout_requirements?(runout, slide_platform_height)
  end

  def completion_percentage
    total_fields = 10 # Total assessable fields
    completed_fields = [
      slide_platform_height, slide_wall_height, runout,
      slide_first_metre_height, slide_beyond_first_metre_height,
      slide_platform_height_comment
    ].count(&:present?) + [
      clamber_netting_pass, runout_pass, slip_sheet_pass,
      slide_permanent_roof
    ].count { |field| !field.nil? }

    (completed_fields.to_f / total_fields * 100).round(0)
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

  private

  def slide_measurements_present?
    slide_platform_height.present? && runout.present? && slide_wall_height.present?
  end

  def safety_assessments_complete?
    [clamber_netting_pass, runout_pass, slip_sheet_pass].none?(&:nil?)
  end
end
