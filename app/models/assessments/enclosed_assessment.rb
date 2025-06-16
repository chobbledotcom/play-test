class Assessments::EnclosedAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  belongs_to :inspection

  validates :inspection_id,
    presence: true,
    uniqueness: true

  validates :exit_number,
    numericality: {greater_than: 0},
    allow_blank: true
end
