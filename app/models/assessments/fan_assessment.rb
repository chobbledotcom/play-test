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
