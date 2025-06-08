# RPII Utility - User Height and Capacity Assessment model
class UserHeightAssessment < ApplicationRecord
  belongs_to :inspection

  # Height measurements (2 decimal places)
  validates :containing_wall_height, :platform_height, :user_height,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # User capacity counts
  validates :users_at_1000mm, :users_at_1200mm, :users_at_1500mm, :users_at_1800mm,
    numericality: {greater_than_or_equal_to: 0, only_integer: true}, allow_blank: true

  # Play area dimensions
  validates :play_area_length, :play_area_width, :negative_adjustment,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  # Callbacks
  after_update :log_assessment_update, if: :saved_changes?

  def complete?
    required_fields_present? && height_measurements_valid?
  end

  def meets_height_requirements?
    return false unless user_height.present? && containing_wall_height.present?

    SafetyStandard.meets_height_requirements?(user_height, containing_wall_height)
  end

  def total_user_capacity
    [users_at_1000mm, users_at_1200mm, users_at_1500mm, users_at_1800mm].compact.sum
  end

  def safety_check_count
    5 # Number of height-related safety checks
  end

  def passed_checks_count
    checks = []
    checks << meets_height_requirements?
    checks << permanent_roof_compliant?
    checks << user_capacity_appropriate?
    checks << play_area_adequate?
    checks << negative_adjustments_reasonable?

    checks.count(true)
  end

  def completion_percentage
    total_fields = 12 # Total number of assessable fields
    completed_fields = [
      containing_wall_height, platform_height, user_height,
      users_at_1000mm, users_at_1200mm, users_at_1500mm, users_at_1800mm,
      play_area_length, play_area_width, negative_adjustment,
      user_height_comment
    ].count(&:present?) + (permanent_roof.nil? ? 0 : 1)

    (completed_fields.to_f / total_fields * 100).round(0)
  end

  def recommended_user_capacity
    return {} unless play_area_length.present? && play_area_width.present?

    SafetyStandard.calculate_user_capacity(play_area_length, play_area_width, negative_adjustment)
  end

  # Alias for view compatibility
  alias_method :calculated_capacities, :recommended_user_capacity

  private

  def required_fields_present?
    containing_wall_height.present? && platform_height.present? && user_height.present?
  end

  def height_measurements_valid?
    return true unless containing_wall_height.present? && platform_height.present?
    containing_wall_height >= platform_height
  end

  def permanent_roof_compliant?
    # Business logic for permanent roof requirements based on height
    return true unless user_height.present?

    if user_height > 6.0
      permanent_roof == true
    else
      true # Not required for lower heights
    end
  end

  def user_capacity_appropriate?
    total_user_capacity > 0 && total_user_capacity <= maximum_safe_capacity
  end

  def maximum_safe_capacity
    return 50 unless play_area_length.present? && play_area_width.present?

    # Maximum 1 person per 1.5 square meters
    usable_area = (play_area_length * play_area_width) - (negative_adjustment || 0)
    (usable_area / 1.5).floor
  end

  def play_area_adequate?
    play_area_length.present? && play_area_width.present? &&
      play_area_length > 0 && play_area_width > 0
  end

  def negative_adjustments_reasonable?
    return true unless negative_adjustment.present?
    return true unless play_area_length.present? && play_area_width.present?

    total_area = play_area_length * play_area_width
    negative_adjustment < (total_area * 0.3) # Should not exceed 30% of total area
  end

  def log_assessment_update
    inspection.log_audit_action("assessment_updated", inspection.user, "User Height Assessment updated")
  end
end
