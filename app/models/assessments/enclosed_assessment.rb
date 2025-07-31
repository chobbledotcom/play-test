class Assessments::EnclosedAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :inspection_id,
    uniqueness: true
end
