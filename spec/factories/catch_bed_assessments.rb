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
      type_of_unit { "Standard catch bed" }
      max_user_mass_marking_pass { true }
      arrest_pass { true }
      matting_pass { true }
      design_risk_pass { true }
      intended_play_pass { true }
      ancillary_fit_pass { true }
      ancillary_compliant_pass { true }
      apron_pass { true }
      trough_pass { true }
      framework_pass { true }
      grounding_pass { true }
      bed_height { 450 }
      bed_height_pass { true }
      platform_fall_distance { 1.2 }
      platform_fall_distance_pass { true }
      blower_tube_length { 3.0 }
      blower_tube_length_pass { true }
    end

    trait :complete do
      type_of_unit { "Standard catch bed" }
      max_user_mass_marking_pass { true }
      max_user_mass_marking_comment { SeedData::OK }
      arrest_pass { true }
      arrest_comment { SeedData::PASS }
      matting_pass { true }
      matting_comment { SeedData::GOOD }
      design_risk_pass { true }
      design_risk_comment { SeedData::PASS }
      intended_play_pass { true }
      intended_play_comment { SeedData::PASS }
      ancillary_fit_pass { true }
      ancillary_fit_comment { SeedData::OK }
      ancillary_compliant_pass { true }
      ancillary_compliant_comment { SeedData::OK }
      apron_pass { true }
      apron_comment { SeedData::GOOD }
      trough_pass { true }
      trough_comment { SeedData::OK }
      framework_pass { true }
      framework_comment { SeedData::PASS }
      grounding_pass { true }
      grounding_comment { SeedData::PASS }
      bed_height { 450 }
      bed_height_pass { true }
      bed_height_comment { SeedData::OK }
      platform_fall_distance { 1.2 }
      platform_fall_distance_pass { true }
      platform_fall_distance_comment { SeedData::OK }
      blower_tube_length { 3.0 }
      blower_tube_length_pass { true }
      blower_tube_length_comment { SeedData::OK }
    end

    trait :failed do
      type_of_unit { "Inflatable catch bed" }
      max_user_mass_marking_pass { false }
      arrest_pass { false }
      matting_pass { true }
      design_risk_pass { false }
      intended_play_pass { true }
      ancillary_fit_pass { false }
      ancillary_compliant_pass { false }
      apron_pass { true }
      trough_pass { false }
      framework_pass { false }
      grounding_pass { false }
      bed_height { 350 }
      bed_height_pass { false }
      platform_fall_distance { 0.5 }
      platform_fall_distance_pass { false }
      blower_tube_length { 2.0 }
      blower_tube_length_pass { false }
    end
  end
end
