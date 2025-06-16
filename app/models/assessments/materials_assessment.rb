class Assessments::MaterialsAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :ropes,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  after_update :log_assessment_update, if: :saved_changes?

  def ropes_compliant? = SafetyStandard.valid_rope_diameter?(ropes)
end
