# RPII Utility - Slide Assessment model
class SlideAssessment < ApplicationRecord
  belongs_to :inspection

  # Slide measurements
  validates :slide_platform_height, :slide_wall_height, :runout_value,
    :slide_first_metre_height, :slide_beyond_first_metre_height,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # Pass/fail assessments
  validates :clamber_netting_pass, :runout_pass, :slip_sheet_pass,
    inclusion: {in: [true, false]}, allow_nil: true

  # Callbacks
  after_update :log_assessment_update, if: :saved_changes?

  def complete?
    slide_measurements_present? && safety_assessments_complete?
  end

  def meets_runout_requirements?
    return false unless runout_value.present? && slide_platform_height.present?

    SafetyStandard.meets_runout_requirements?(runout_value, slide_platform_height)
  end

  def safety_check_count
    3 # clamber_netting, runout, slip_sheet
  end

  def passed_checks_count
    [clamber_netting_pass, runout_pass, slip_sheet_pass].count(true)
  end

  def completion_percentage
    total_fields = 10 # Total assessable fields
    completed_fields = [
      slide_platform_height, slide_wall_height, runout_value,
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
    return "Not Assessed" unless runout_value.present?

    if meets_runout_requirements?
      "Compliant"
    else
      "Non-Compliant (Requires #{required_runout_length}m minimum)"
    end
  end

  private

  def slide_measurements_present?
    slide_platform_height.present? && runout_value.present? && slide_wall_height.present?
  end

  def safety_assessments_complete?
    [clamber_netting_pass, runout_pass, slip_sheet_pass].none?(&:nil?)
  end

  def log_assessment_update
    inspection.log_audit_action("assessment_updated", inspection.user, "Slide Assessment updated")
  end
end
