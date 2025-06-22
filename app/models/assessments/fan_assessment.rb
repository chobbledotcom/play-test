class Assessments::FanAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :inspection_id,
    uniqueness: true
end
