class FanAssessment < ApplicationRecord
  belongs_to :inspection

  validates :inspection_id, presence: true, uniqueness: true
end
