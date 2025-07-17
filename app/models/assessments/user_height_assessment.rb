class Assessments::UserHeightAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :inspection_id,
    uniqueness: true

  validates :containing_wall_height,
    :platform_height, :tallest_user_height,
    numericality: { greater_than_or_equal_to: 0 },
    allow_blank: true

  validates :users_at_1000mm,
    :users_at_1200mm,
    :users_at_1500mm,
    :users_at_1800mm,
    numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_blank: true

  validates :play_area_length,
    :play_area_width,
    :negative_adjustment,
    numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  def meets_height_requirements?
    return false unless platform_height.present? && tallest_user_height.present? && containing_wall_height.present?

    permanent_roof = permanent_roof_status
    return false if permanent_roof.nil?

    SafetyStandards::SlideCalculator.meets_height_requirements?(
      platform_height,
      tallest_user_height,
      containing_wall_height,
      permanent_roof
    )
  end

  private

  def permanent_roof_status
    # Permanent roof only matters for platforms 3.0m and above
    return false if platform_height < 3.0

    # For platforms 3.0m+, check slide assessment if inspection has a slide
    return false unless inspection.has_slide?

    inspection.slide_assessment?&.slide_permanent_roof
  end
end
