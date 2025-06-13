class Assessments::FanAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  belongs_to :inspection

  validates :inspection_id, presence: true, uniqueness: true

  # Fan safety checks
  SAFETY_CHECKS = %w[blower_serial_pass blower_flap_pass blower_finger_pass blower_visual_pass pat_pass].freeze

  # Pass/fail validations
  SAFETY_CHECKS.each do |check|
    validates check.to_sym, inclusion: {in: [true, false]}, allow_nil: true
  end

  def has_critical_failures?
    SAFETY_CHECKS.any? { |check| send(check) == false }
  end

  def safety_issues_summary
    failures = SAFETY_CHECKS.select { |check| send(check) == false }
    return "No safety issues" if failures.empty?

    "Safety issues: #{failures.map(&:humanize).join(", ")}"
  end

  private
end
