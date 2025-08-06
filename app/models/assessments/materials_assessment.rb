# == Schema Information
#
# Table name: materials_assessments
#
#  id                        :integer          not null
#  inspection_id             :string(8)        not null, primary key
#  ropes                     :integer
#  ropes_pass                :integer
#  retention_netting_pass    :integer
#  zips_pass                 :integer
#  windows_pass              :integer
#  artwork_pass              :integer
#  thread_pass               :boolean
#  fabric_strength_pass      :boolean
#  fire_retardant_pass       :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  ropes_comment             :text
#  retention_netting_comment :text
#  zips_comment              :text
#  windows_comment           :text
#  artwork_comment           :text
#  thread_comment            :text
#  fabric_strength_comment   :text
#  fire_retardant_comment    :text
#
# Indexes
#
#  index_materials_assessments_on_inspection_id  (inspection_id)
#

# typed: true
# frozen_string_literal: true

class Assessments::MaterialsAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  enum :ropes_pass, Inspection::PASS_FAIL_NA
  enum :retention_netting_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :zips_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :windows_pass, Inspection::PASS_FAIL_NA, prefix: true
  enum :artwork_pass, Inspection::PASS_FAIL_NA, prefix: true

  after_update :log_assessment_update, if: :saved_changes?

  sig { returns(T::Boolean) }
  def ropes_compliant?
    EN14960.valid_rope_diameter?(ropes)
  end
end
