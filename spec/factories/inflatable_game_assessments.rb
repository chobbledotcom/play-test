# typed: false

FactoryBot.define do
  factory :inflatable_game_assessment,
    class: "Assessments::InflatableGameAssessment" do
    association :inspection

    # Comment-only field
    game_type { nil }

    # Pass/fail assessments
    max_user_mass_pass { nil }
    age_range_marking_pass { nil }
    constant_air_flow_pass { nil }
    design_risk_pass { nil }
    intended_play_risk_pass { nil }
    ancillary_equipment_pass { nil }
    ancillary_equipment_compliant_pass { nil }
    containing_wall_height_pass { nil }

    # Measurements
    containing_wall_height { nil }

    trait :passed do
      maximum_users { 4 }
      max_user_mass { 120 }
      minimum_age { 1 }
      maximum_age { 16 }
      game_type { "Standard inflatable obstacle course" }
      max_user_mass_pass { "pass" }
      age_range_marking_pass { "pass" }
      constant_air_flow_pass { "pass" }
      design_risk_pass { "pass" }
      intended_play_risk_pass { "pass" }
      ancillary_equipment_pass { "pass" }
      ancillary_equipment_compliant_pass { "pass" }
      containing_wall_height { 1.5 }
      containing_wall_height_pass { "pass" }
    end

    trait :complete do
      maximum_users { 4 }
      max_user_mass { 120 }
      minimum_age { 1 }
      maximum_age { 16 }
      game_type { "Standard inflatable obstacle course" }
      max_user_mass_pass { "pass" }
      max_user_mass_comment { SeedData::OK }
      age_range_marking_pass { "pass" }
      age_range_marking_comment { SeedData::OK }
      constant_air_flow_pass { "pass" }
      constant_air_flow_comment { SeedData::PASS }
      design_risk_pass { "pass" }
      design_risk_comment { SeedData::PASS }
      intended_play_risk_pass { "pass" }
      intended_play_risk_comment { SeedData::PASS }
      ancillary_equipment_pass { "pass" }
      ancillary_equipment_comment { SeedData::OK }
      ancillary_equipment_compliant_pass { "pass" }
      ancillary_equipment_compliant_comment { SeedData::OK }
      containing_wall_height { 1.5 }
      containing_wall_height_pass { "pass" }
      containing_wall_height_comment { SeedData::OK }
    end

    trait :failed do
      game_type { "Inflatable assault course" }
      max_user_mass_pass { "fail" }
      age_range_marking_pass { "fail" }
      constant_air_flow_pass { "pass" }
      design_risk_pass { "fail" }
      intended_play_risk_pass { "pass" }
      ancillary_equipment_pass { "fail" }
      ancillary_equipment_compliant_pass { "fail" }
      containing_wall_height { 0.8 }
      containing_wall_height_pass { "fail" }
    end
  end
end
