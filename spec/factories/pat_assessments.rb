# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :pat_assessment, class: "Assessments::PatAssessment" do
    association :inspection

    # All fields default to nil for tests to control
    location { nil }
    equipment_class { nil }
    equipment_class_pass { nil }
    equipment_power { nil }
    visual_pass { nil }
    appliance_plug_check_pass { nil }
    fuse_rating { nil }
    fuse_rating_pass { nil }
    earth_ohms { nil }
    earth_ohms_pass { nil }
    insulation_mohms { nil }
    insulation_mohms_pass { nil }
    leakage_ma { nil }
    leakage_ma_pass { nil }
    load_test_pass { nil }
    rcd_trip_time_ms { nil }
    rcd_trip_time_ms_pass { nil }

    trait :passed do
      location { "Office" }
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
      location { "Office" }
      location_comment { "Ground floor office" }
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
      location { "Workshop" }
      equipment_class { 1 }
      equipment_class_pass { false }
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
