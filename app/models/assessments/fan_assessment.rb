class Assessments::FanAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  belongs_to :inspection

  validates :inspection_id,
    presence: true,
    uniqueness: true
end
