class EnclosedAssessment < ApplicationRecord
  belongs_to :inspection

  validates :inspection_id, presence: true, uniqueness: true
  validates :exit_number, numericality: {greater_than: 0}, allow_blank: true
end
