# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: pat_assessments
#
#  appliance_plug_check_comment :text
#  appliance_plug_check_pass    :boolean
#  earth_ohms                   :decimal(8, 2)
#  earth_ohms_comment           :text
#  earth_ohms_pass              :boolean
#  equipment_class              :integer
#  equipment_class_comment      :text
#  equipment_class_pass         :boolean
#  equipment_power              :integer
#  equipment_power_comment      :text
#  fuse_rating                  :integer
#  fuse_rating_comment          :text
#  fuse_rating_pass             :boolean
#  insulation_mohms             :integer
#  insulation_mohms_comment     :text
#  insulation_mohms_pass        :boolean
#  leakage_ma                   :decimal(8, 2)
#  leakage_ma_comment           :text
#  leakage_ma_pass              :boolean
#  load_test_comment            :text
#  load_test_pass               :boolean
#  rcd_trip_time_ms             :decimal(8, 2)
#  rcd_trip_time_ms_comment     :text
#  rcd_trip_time_ms_pass        :boolean
#  visual_comment               :text
#  visual_pass                  :boolean
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  inspection_id                :string(12)       not null, primary key
#
# Indexes
#
#  pat_assessments_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
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
