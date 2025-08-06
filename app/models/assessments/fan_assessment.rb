# == Schema Information
#
# Table name: fan_assessments
#
#  inspection_id              :string(12)       not null, primary key
#  fan_size_type              :text
#  blower_flap_pass           :integer
#  blower_flap_comment        :text
#  blower_finger_pass         :boolean
#  blower_finger_comment      :text
#  pat_pass                   :integer
#  pat_comment                :text
#  blower_visual_pass         :boolean
#  blower_visual_comment      :text
#  blower_serial              :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  number_of_blowers          :integer
#  blower_tube_length         :decimal(8, 2)
#  blower_tube_length_pass    :boolean
#  blower_tube_length_comment :text
#
# Indexes
#
#  fan_assessments_new_pkey  (inspection_id) UNIQUE
#

# typed: true
# frozen_string_literal: true

class Assessments::FanAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  enum :pat_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :blower_flap_pass, Inspection::PASS_FAIL_NA, prefix: true

  validates :inspection_id,
    uniqueness: true
end
