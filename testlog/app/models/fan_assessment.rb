class FanAssessment < ApplicationRecord
  belongs_to :inspection

  validates :inspection_id, presence: true, uniqueness: true

  # Fan safety checks
  SAFETY_CHECKS = %w[blower_flap_pass blower_finger_pass blower_visual_pass pat_pass].freeze

  # Pass/fail validations
  SAFETY_CHECKS.each do |check|
    validates check.to_sym, inclusion: {in: [true, false]}, allow_nil: true
  end

  def complete?
    safety_checks_assessed? && specifications_present?
  end

  def has_critical_failures?
    SAFETY_CHECKS.any? { |check| send(check) == false }
  end

  def safety_check_count
    SAFETY_CHECKS.length
  end

  def passed_checks_count
    SAFETY_CHECKS.count { |check| send(check) == true }
  end

  def completion_percentage
    total_fields = 6 # 4 safety checks + serial + comment
    completed_fields = (
      SAFETY_CHECKS.map { |check| send(check) } +
      [blower_serial, fan_size_comment]
    ).count(&:present?)

    (completed_fields.to_f / total_fields * 100).round(0)
  end

  def safety_issues_summary
    failures = SAFETY_CHECKS.select { |check| send(check) == false }
    return "No safety issues" if failures.empty?

    "Safety issues: #{failures.map(&:humanize).join(", ")}"
  end

  private

  def safety_checks_assessed?
    SAFETY_CHECKS.all? { |check| !send(check).nil? }
  end

  def specifications_present?
    blower_serial.present? && fan_size_comment.present?
  end
end
