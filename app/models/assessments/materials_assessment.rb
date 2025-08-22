# == Schema Information
#
# Table name: materials_assessments
#
#  id                        :integer          not null
#  artwork_comment           :text
#  artwork_pass              :integer
#  fabric_strength_comment   :text
#  fabric_strength_pass      :boolean
#  fire_retardant_comment    :text
#  fire_retardant_pass       :boolean
#  retention_netting_comment :text
#  retention_netting_pass    :integer
#  ropes                     :integer
#  ropes_comment             :text
#  ropes_pass                :integer
#  thread_comment            :text
#  thread_pass               :boolean
#  windows_comment           :text
#  windows_pass              :integer
#  zips_comment              :text
#  zips_pass                 :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  inspection_id             :string(8)        not null, primary key
#
# Indexes
#
#  index_materials_assessments_on_inspection_id  (inspection_id)
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
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
end
