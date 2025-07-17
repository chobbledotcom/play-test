class Assessments::EnclosedAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :inspection_id,
    uniqueness: true

  validates :exit_number,
    numericality: { greater_than: 0 },
    allow_blank: true
end
