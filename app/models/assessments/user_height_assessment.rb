# == Schema Information
#
# Table name: user_height_assessments
#
#  inspection_id                     :string(12)       not null, primary key
#  containing_wall_height            :decimal(8, 2)
#  containing_wall_height_comment    :text
#  tallest_user_height               :decimal(8, 2)
#  tallest_user_height_comment       :text
#  play_area_length                  :decimal(8, 2)
#  play_area_length_comment          :text
#  play_area_width                   :decimal(8, 2)
#  play_area_width_comment           :text
#  negative_adjustment               :decimal(8, 2)
#  negative_adjustment_comment       :text
#  users_at_1000mm                   :integer
#  users_at_1200mm                   :integer
#  users_at_1500mm                   :integer
#  users_at_1800mm                   :integer
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  user_count_at_maximum_user_height :integer
#
# Indexes
#
#  user_height_assessments_new_pkey  (inspection_id) UNIQUE
#

# typed: true
# frozen_string_literal: true

class Assessments::UserHeightAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  validates :inspection_id,
    uniqueness: true
end
