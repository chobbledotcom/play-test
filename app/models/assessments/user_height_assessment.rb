class Assessments::UserHeightAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  belongs_to :inspection

  validates :inspection_id,
    presence: true,
    uniqueness: true

  validates :containing_wall_height,
    :platform_height, :tallest_user_height,
    numericality: {greater_than_or_equal_to: 0},
    allow_blank: true

  validates :users_at_1000mm,
    :users_at_1200mm,
    :users_at_1500mm,
    :users_at_1800mm,
    numericality: {greater_than_or_equal_to: 0, only_integer: true}, allow_blank: true

  validates :play_area_length,
    :play_area_width,
    :negative_adjustment,
    numericality: {greater_than_or_equal_to: 0}, allow_blank: true

  def meets_height_requirements?
    return false unless tallest_user_height.present? && containing_wall_height.present?

    SafetyStandard.meets_height_requirements?(tallest_user_height, containing_wall_height)
  end

  def recommended_user_capacity
    return {} unless play_area_length.present? && play_area_width.present?
    SafetyStandard.calculate_user_capacity(
      play_area_length,
      play_area_width,
      negative_adjustment
    )
  end
end
