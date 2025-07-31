class Assessments::MaterialsAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  enum :ropes_pass, Inspection::PASS_FAIL_NA
  enum :retention_netting_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :zips_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :windows_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :artwork_pass, Inspection::PASS_FAIL_NA, prefix: true

  after_update :log_assessment_update, if: :saved_changes?

  def ropes_compliant?
    EN14960.valid_rope_diameter?(ropes)
  end
end
