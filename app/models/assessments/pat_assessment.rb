# typed: true
# frozen_string_literal: true

class Assessments::PatAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  after_update :log_assessment_update, if: :saved_changes?
end
