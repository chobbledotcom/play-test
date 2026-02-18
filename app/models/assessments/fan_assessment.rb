# == Schema Information
#
# Table name: fan_assessments
#
#  blower_finger_comment      :text
#  blower_finger_pass         :boolean
#  blower_flap_comment        :text
#  blower_flap_pass           :integer
#  blower_serial              :string
#  blower_tube_length         :decimal(8, 2)
#  blower_tube_length_comment :text
#  blower_tube_length_pass    :boolean
#  blower_visual_comment      :text
#  blower_visual_pass         :boolean
#  fan_size_type              :text
#  number_of_blowers          :integer
#  pat_comment                :text
#  pat_pass                   :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  inspection_id              :string(12)       not null, primary key
#
# Indexes
#
#  fan_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

# typed: true
# frozen_string_literal: true

class Assessments::FanAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include ColumnNameSyms
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  enum :pat_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :blower_flap_pass, Inspection::PASS_FAIL_NA, prefix: true

  validates :inspection_id,
    uniqueness: true
end
