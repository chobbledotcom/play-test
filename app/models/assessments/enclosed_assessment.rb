class Assessments::EnclosedAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  belongs_to :inspection

  validates :inspection_id, presence: true, uniqueness: true
  validates :exit_number, numericality: {greater_than: 0}, allow_blank: true
  validates :exit_number_pass, :exit_sign_always_visible_pass, :exit_sign_visible_pass,
    inclusion: {in: [true, false]}, allow_nil: true

  def has_critical_failures?
    exit_number_pass == false || exit_sign_always_visible_pass == false || exit_sign_visible_pass == false
  end

  def critical_failure_summary
    failures = []
    failures << "Insufficient exits" if exit_number_pass == false
    failures << "Exit signs not always visible" if exit_sign_always_visible_pass == false
    failures << "Exit signs not visible" if exit_sign_visible_pass == false
    failures.join(", ")
  end
end
