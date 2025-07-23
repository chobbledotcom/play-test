class Assessments::StructureAssessment < ApplicationRecord
  include AssessmentLogging
  include AssessmentCompletion

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :unit_pressure,
    :blower_tube_length,
    :step_ramp_size,
    :critical_fall_off_height,
    :trough_depth,
    :trough_adjacent_panel_width,
    numericality: {greater_than_or_equal_to: 0},
    allow_blank: true

  after_update :log_assessment_update, if: :saved_changes?
end
