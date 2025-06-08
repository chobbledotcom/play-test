class EnclosedAssessment < ApplicationRecord
  belongs_to :inspection

  validates :inspection_id, presence: true, uniqueness: true
  validates :exit_number, numericality: {greater_than: 0}, allow_blank: true

  # Required assessment methods
  def complete?
    exit_number.present? &&
      exit_number_pass.present? &&
      exit_visible_pass.present?
  end

  def completion_percentage
    total_fields = 3 # exit_number, exit_number_pass, exit_visible_pass
    completed_fields = 0

    completed_fields += 1 if exit_number.present?
    completed_fields += 1 if exit_number_pass.present?
    completed_fields += 1 if exit_visible_pass.present?

    (completed_fields.to_f / total_fields * 100).round(0)
  end

  def passed_checks_count
    count = 0
    count += 1 if exit_number_pass == true
    count += 1 if exit_visible_pass == true
    count
  end

  def safety_check_count
    2 # exit_number_pass and exit_visible_pass
  end

  def has_critical_failures?
    exit_number_pass == false || exit_visible_pass == false
  end

  def critical_failure_summary
    failures = []
    failures << "Insufficient exits" if exit_number_pass == false
    failures << "Exits not clearly visible" if exit_visible_pass == false
    failures.join(", ")
  end
end
