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
      blower_forward_distance_pass { true }
      marking_max_mass_pass { true }
      marking_min_height_pass { true }
      pull_strength_pass { true }
      cord_length_max_pass { true }
      cord_diametre_min_pass { true }
      two_stage_locking_pass { true }
      baton_compliant_pass { true }
      lane_width_max_pass { true }
      rear_wall_pass { true }
      side_wall_pass { true }
      running_wall_pass { true }
      harness_width { 200 }
      harness_width_pass { true }
      num_of_cords { 2 }
      rear_wall_thickness { 0.6 }
      rear_wall_height { 1.8 }
      side_wall_length { 1.5 }
      side_wall_height { 1.7 }
      running_wall_width { 0.45 }
      running_wall_height { 0.9 }
    end

    trait :complete do
      blower_forward_distance_pass { true }
      blower_forward_distance_comment { SeedData::OK }
      marking_max_mass_pass { true }
      marking_max_mass_comment { SeedData::OK }
      marking_min_height_pass { true }
      marking_min_height_comment { SeedData::OK }
      pull_strength_pass { true }
      pull_strength_comment { SeedData::PASS }
      cord_length_max_pass { true }
      cord_length_max_comment { SeedData::OK }
      cord_diametre_min_pass { true }
      cord_diametre_min_comment { SeedData::OK }
      two_stage_locking_pass { true }
      two_stage_locking_comment { SeedData::PASS }
      baton_compliant_pass { true }
      baton_compliant_comment { SeedData::PASS }
      lane_width_max_pass { true }
      lane_width_max_comment { SeedData::OK }
      rear_wall_pass { true }
      rear_wall_comment { SeedData::OK }
      side_wall_pass { true }
      side_wall_comment { SeedData::OK }
      running_wall_pass { true }
      running_wall_comment { SeedData::OK }
      harness_width { 200 }
      harness_width_pass { true }
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
      blower_forward_distance_pass { false }
      marking_max_mass_pass { false }
      marking_min_height_pass { false }
      pull_strength_pass { false }
      cord_length_max_pass { false }
      cord_diametre_min_pass { false }
      two_stage_locking_pass { false }
      baton_compliant_pass { false }
      lane_width_max_pass { false }
      rear_wall_pass { false }
      side_wall_pass { false }
      running_wall_pass { false }
      harness_width { 150 }
      harness_width_pass { false }
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
