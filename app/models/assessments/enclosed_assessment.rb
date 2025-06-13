class Assessments::EnclosedAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  
  belongs_to :inspection

  validates :inspection_id, presence: true, uniqueness: true
  validates :exit_number, numericality: {greater_than: 0}, allow_blank: true
  validates :exit_number_pass, :exit_sign_always_visible_pass, :exit_sign_visible_pass, 
    inclusion: {in: [true, false]}, allow_nil: true

  # Required assessment methods
  def complete?
    exit_number.present? &&
      exit_number_pass.present? &&
      exit_sign_always_visible_pass.present? &&
      exit_sign_visible_pass.present?
  end

  def completion_percentage
    total_fields = 4 # exit_number, exit_number_pass, exit_sign_always_visible_pass, exit_sign_visible_pass
    completed_fields = 0

    completed_fields += 1 if exit_number.present?
    completed_fields += 1 if exit_number_pass.present?
    completed_fields += 1 if exit_sign_always_visible_pass.present?
    completed_fields += 1 if exit_sign_visible_pass.present?

    (completed_fields.to_f / total_fields * 100).round(0)
  end


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
