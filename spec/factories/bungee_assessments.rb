# typed: false

FactoryBot.define do
  factory :bungee_assessment,
    class: "Assessments::BungeeAssessment" do
    association :inspection

    # Pass/fail assessments
    blower_forward_distance_pass { nil }
    marking_max_mass_pass { nil }
    marking_min_height_pass { nil }
    pull_strength_pass { nil }
    cord_length_max_pass { nil }
    cord_diametre_min_pass { nil }
    two_stage_locking_pass { nil }
    baton_compliant_pass { nil }
    lane_width_max_pass { nil }
    rear_wall_pass { nil }
    side_wall_pass { nil }
    running_wall_pass { nil }
    harness_width_pass { nil }

    # Measurements
    harness_width { nil }
    num_of_cords { nil }
    rear_wall_thickness { nil }
    rear_wall_height { nil }
    side_wall_length { nil }
    side_wall_height { nil }
    running_wall_width { nil }
    running_wall_height { nil }

    trait :passed do
      maximum_users { 4 }
      marking_max_mass { 120 }
      marking_min_height { 1.2 }
      pull_strength { 2400 }
      blower_forward_distance_pass { "pass" }
      marking_max_mass_pass { "pass" }
      marking_min_height_pass { "pass" }
      pull_strength_pass { "pass" }
      cord_length_max_pass { "pass" }
      cord_diametre_min_pass { "pass" }
      two_stage_locking_pass { "pass" }
      baton_compliant_pass { "pass" }
      lane_width_max_pass { "pass" }
      rear_wall_pass { "pass" }
      side_wall_pass { "pass" }
      running_wall_pass { "pass" }
      harness_width { 200 }
      harness_width_pass { "pass" }
      num_of_cords { 2 }
      rear_wall_thickness { 0.6 }
      rear_wall_height { 1.8 }
      side_wall_length { 1.5 }
      side_wall_height { 1.7 }
      running_wall_width { 0.45 }
      running_wall_height { 0.9 }
    end

    trait :complete do
      maximum_users { 4 }
      marking_max_mass { 120 }
      marking_min_height { 1.2 }
      pull_strength { 2400 }
      blower_forward_distance_pass { "pass" }
      blower_forward_distance_comment { SeedData::OK }
      marking_max_mass_pass { "pass" }
      marking_max_mass_comment { SeedData::OK }
      marking_min_height_pass { "pass" }
      marking_min_height_comment { SeedData::OK }
      pull_strength_pass { "pass" }
      pull_strength_comment { SeedData::PASS }
      cord_length_max_pass { "pass" }
      cord_length_max_comment { SeedData::OK }
      cord_diametre_min_pass { "pass" }
      cord_diametre_min_comment { SeedData::OK }
      two_stage_locking_pass { "pass" }
      two_stage_locking_comment { SeedData::PASS }
      baton_compliant_pass { "pass" }
      baton_compliant_comment { SeedData::PASS }
      lane_width_max_pass { "pass" }
      lane_width_max_comment { SeedData::OK }
      rear_wall_pass { "pass" }
      rear_wall_comment { SeedData::OK }
      side_wall_pass { "pass" }
      side_wall_comment { SeedData::OK }
      running_wall_pass { "pass" }
      running_wall_comment { SeedData::OK }
      harness_width { 200 }
      harness_width_pass { "pass" }
      harness_width_comment { SeedData::OK }
      num_of_cords { 2 }
      rear_wall_thickness { 0.6 }
      rear_wall_height { 1.8 }
      side_wall_length { 1.5 }
      side_wall_height { 1.7 }
      running_wall_width { 0.45 }
      running_wall_height { 0.9 }
    end

    trait :failed do
      blower_forward_distance_pass { "fail" }
      marking_max_mass_pass { "fail" }
      marking_min_height_pass { "fail" }
      pull_strength_pass { "fail" }
      cord_length_max_pass { "fail" }
      cord_diametre_min_pass { "fail" }
      two_stage_locking_pass { "fail" }
      baton_compliant_pass { "fail" }
      lane_width_max_pass { "fail" }
      rear_wall_pass { "fail" }
      side_wall_pass { "fail" }
      running_wall_pass { "fail" }
      harness_width { 150 }
      harness_width_pass { "fail" }
      num_of_cords { 1 }
      rear_wall_thickness { 0.4 }
      rear_wall_height { 1.2 }
      side_wall_length { 1.0 }
      side_wall_height { 1.2 }
      running_wall_width { 0.3 }
      running_wall_height { 0.6 }
    end
  end
end
