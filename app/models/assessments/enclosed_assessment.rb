# == Schema Information
#
# Table name: enclosed_assessments
#
#  id                               :integer          not null
#  exit_number                      :integer
#  exit_number_comment              :text
#  exit_number_pass                 :boolean
#  exit_sign_always_visible_comment :text
#  exit_sign_always_visible_pass    :boolean
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  inspection_id                    :string(8)        not null, primary key
#
# Indexes
#
#  index_enclosed_assessments_on_inspection_id  (inspection_id)
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
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
