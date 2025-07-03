class Assessments::UserHeightAssessment < ApplicationRecord
  include AssessmentLogging
  include SafetyCheckMethods
  include AssessmentCompletion

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :inspection_id,
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
    return false unless platform_height.present? && tallest_user_height.present? && containing_wall_height.present? && !has_permanent_roof.nil?

    SafetyStandards::SlideCalculator.meets_height_requirements?(platform_height, tallest_user_height, containing_wall_height, has_permanent_roof)
  end
end
