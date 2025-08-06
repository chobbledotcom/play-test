# == Schema Information
#
# Table name: enclosed_assessments
#
#  inspection_id                    :string(12)       not null, primary key
#  exit_number                      :integer
#  exit_number_pass                 :boolean
#  exit_number_comment              :text
#  exit_sign_always_visible_pass    :boolean
#  exit_sign_always_visible_comment :text
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#
# Indexes
#
#  enclosed_assessments_new_pkey  (inspection_id) UNIQUE
#

# typed: true
# frozen_string_literal: true

class Assessments::EnclosedAssessment < ApplicationRecord
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
