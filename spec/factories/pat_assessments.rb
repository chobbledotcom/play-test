# typed: false
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
FactoryBot.define do
  factory :pat_assessment, class: "Assessments::PatAssessment" do
    association :inspection

    trait :passed do
      equipment_class { 1 }
      equipment_class_pass { true }
      equipment_power { 500 }
      visual_pass { true }
      appliance_plug_check_pass { true }
      fuse_rating { 13 }
      fuse_rating_pass { true }
      earth_ohms { 0.1 }
      earth_ohms_pass { true }
      insulation_mohms { 200 }
      insulation_mohms_pass { true }
      leakage_ma { 0.5 }
      leakage_ma_pass { true }
      load_test_pass { true }
      rcd_trip_time_ms { 25.0 }
      rcd_trip_time_ms_pass { true }
    end

    trait :complete do
      equipment_class { 1 }
      equipment_class_pass { true }
      equipment_class_comment { "Class I appliance" }
      equipment_power { 500 }
      equipment_power_comment { "500W heater" }
      visual_pass { true }
      visual_comment { "No visible damage" }
      appliance_plug_check_pass { true }
      appliance_plug_check_comment { "Plug in good condition" }
      fuse_rating { 13 }
      fuse_rating_pass { true }
      fuse_rating_comment { "Correct fuse fitted" }
      earth_ohms { 0.1 }
      earth_ohms_pass { true }
      earth_ohms_comment { "Within limits" }
      insulation_mohms { 200 }
      insulation_mohms_pass { true }
      insulation_mohms_comment { "Above minimum" }
      leakage_ma { 0.5 }
      leakage_ma_pass { true }
      leakage_ma_comment { "Within safe limits" }
      load_test_pass { true }
      load_test_comment { "Operates correctly" }
      rcd_trip_time_ms { 25.0 }
      rcd_trip_time_ms_pass { true }
      rcd_trip_time_ms_comment { "RCD trips within time" }
    end

    trait :failed do
      equipment_class { 1 }
      equipment_class_pass { false }
      equipment_power { 500 }
      visual_pass { false }
      appliance_plug_check_pass { false }
      fuse_rating { 13 }
      fuse_rating_pass { false }
      earth_ohms { 2.0 }
      earth_ohms_pass { false }
      insulation_mohms { 0 }
      insulation_mohms_pass { false }
      leakage_ma { 10.0 }
      leakage_ma_pass { false }
      load_test_pass { false }
      rcd_trip_time_ms { 500.0 }
      rcd_trip_time_ms_pass { false }
    end
  end
end
