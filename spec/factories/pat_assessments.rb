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
      equipment_class_pass { "pass" }
      equipment_power { 500 }
      visual_pass { "pass" }
      appliance_plug_check_pass { "pass" }
      fuse_rating { 13 }
      fuse_rating_pass { "pass" }
      earth_ohms { 0.1 }
      earth_ohms_pass { "pass" }
      insulation_mohms { 200 }
      insulation_mohms_pass { "pass" }
      leakage_ma { 0.5 }
      leakage_ma_pass { "pass" }
      load_test_pass { "pass" }
      rcd_trip_time_ms { 25.0 }
      rcd_trip_time_ms_pass { "pass" }
    end

    trait :complete do
      equipment_class { 1 }
      equipment_class_pass { "pass" }
      equipment_class_comment { "Class I appliance" }
      equipment_power { 500 }
      equipment_power_comment { "500W heater" }
      visual_pass { "pass" }
      visual_comment { "No visible damage" }
      appliance_plug_check_pass { "pass" }
      appliance_plug_check_comment { "Plug in good condition" }
      fuse_rating { 13 }
      fuse_rating_pass { "pass" }
      fuse_rating_comment { "Correct fuse fitted" }
      earth_ohms { 0.1 }
      earth_ohms_pass { "pass" }
      earth_ohms_comment { "Within limits" }
      insulation_mohms { 200 }
      insulation_mohms_pass { "pass" }
      insulation_mohms_comment { "Above minimum" }
      leakage_ma { 0.5 }
      leakage_ma_pass { "pass" }
      leakage_ma_comment { "Within safe limits" }
      load_test_pass { "pass" }
      load_test_comment { "Operates correctly" }
      rcd_trip_time_ms { 25.0 }
      rcd_trip_time_ms_pass { "pass" }
      rcd_trip_time_ms_comment { "RCD trips within time" }
    end

    trait :failed do
      equipment_class { 1 }
      equipment_class_pass { "fail" }
      equipment_power { 500 }
      visual_pass { "fail" }
      appliance_plug_check_pass { "fail" }
      fuse_rating { 13 }
      fuse_rating_pass { "fail" }
      earth_ohms { 2.0 }
      earth_ohms_pass { "fail" }
      insulation_mohms { 0 }
      insulation_mohms_pass { "fail" }
      leakage_ma { 10.0 }
      leakage_ma_pass { "fail" }
      load_test_pass { "fail" }
      rcd_trip_time_ms { 500.0 }
      rcd_trip_time_ms_pass { "fail" }
    end
  end
end
