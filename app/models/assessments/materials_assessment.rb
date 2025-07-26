class Assessments::MaterialsAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  enum :ropes_pass, Inspection::PASS_FAIL_NA
  enum :retention_netting_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :zips_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :windows_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :artwork_pass, Inspection::PASS_FAIL_NA, prefix: true

  validates :ropes,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  after_update :log_assessment_update, if: :saved_changes?

  def ropes_compliant?
    SafetyStandards::MaterialValidator.valid_rope_diameter?(ropes)
  end
end
