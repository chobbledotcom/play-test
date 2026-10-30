# typed: false

FactoryBot.define do
  factory :catch_bed_assessment,
    class: "Assessments::CatchBedAssessment" do
    association :inspection

    # Comment-only field
    type_of_unit { nil }

    # Pass/fail assessments
    max_user_mass_marking_pass { nil }
    arrest_pass { nil }
    matting_pass { nil }
    design_risk_pass { nil }
    intended_play_pass { nil }
    ancillary_fit_pass { nil }
    ancillary_compliant_pass { nil }
    apron_pass { nil }
    trough_pass { nil }
    framework_pass { nil }
    grounding_pass { nil }
    bed_height_pass { nil }
    platform_fall_distance_pass { nil }
    blower_tube_length_pass { nil }

    # Measurements
    bed_height { nil }
    platform_fall_distance { nil }
    blower_tube_length { nil }

    trait :passed do
      maximum_users { 4 }
      max_user_mass_marking { 120 }
      type_of_unit { "Standard catch bed" }
      max_user_mass_marking_pass { "pass" }
      arrest_pass { "pass" }
      matting_pass { "pass" }
      design_risk_pass { "pass" }
      intended_play_pass { "pass" }
      ancillary_fit_pass { "pass" }
      ancillary_compliant_pass { "pass" }
      apron_pass { "pass" }
      trough_pass { "pass" }
      framework_pass { "pass" }
      grounding_pass { "pass" }
      bed_height { 450 }
      bed_height_pass { "pass" }
      platform_fall_distance { 1.2 }
      platform_fall_distance_pass { "pass" }
      blower_tube_length { 3.0 }
      blower_tube_length_pass { "pass" }
    end

    trait :complete do
      maximum_users { 4 }
      max_user_mass_marking { 120 }
      type_of_unit { "Standard catch bed" }
      max_user_mass_marking_pass { "pass" }
      max_user_mass_marking_comment { SeedData::OK }
      arrest_pass { "pass" }
      arrest_comment { SeedData::PASS }
      matting_pass { "pass" }
      matting_comment { SeedData::GOOD }
      design_risk_pass { "pass" }
      design_risk_comment { SeedData::PASS }
      intended_play_pass { "pass" }
      intended_play_comment { SeedData::PASS }
      ancillary_fit_pass { "pass" }
      ancillary_fit_comment { SeedData::OK }
      ancillary_compliant_pass { "pass" }
      ancillary_compliant_comment { SeedData::OK }
      apron_pass { "pass" }
      apron_comment { SeedData::GOOD }
      trough_pass { "pass" }
      trough_comment { SeedData::OK }
      framework_pass { "pass" }
      framework_comment { SeedData::PASS }
      grounding_pass { "pass" }
      grounding_comment { SeedData::PASS }
      bed_height { 450 }
      bed_height_pass { "pass" }
      bed_height_comment { SeedData::OK }
      platform_fall_distance { 1.2 }
      platform_fall_distance_pass { "pass" }
      platform_fall_distance_comment { SeedData::OK }
      blower_tube_length { 3.0 }
      blower_tube_length_pass { "pass" }
      blower_tube_length_comment { SeedData::OK }
    end

    trait :failed do
      type_of_unit { "Inflatable catch bed" }
      max_user_mass_marking_pass { "fail" }
      arrest_pass { "fail" }
      matting_pass { "pass" }
      design_risk_pass { "fail" }
      intended_play_pass { "pass" }
      ancillary_fit_pass { "fail" }
      ancillary_compliant_pass { "fail" }
      apron_pass { "pass" }
      trough_pass { "fail" }
      framework_pass { "fail" }
      grounding_pass { "fail" }
      bed_height { 350 }
      bed_height_pass { "fail" }
      platform_fall_distance { 0.5 }
      platform_fall_distance_pass { "fail" }
      blower_tube_length { 2.0 }
      blower_tube_length_pass { "fail" }
    end
  end
end
