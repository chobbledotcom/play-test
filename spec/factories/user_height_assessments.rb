FactoryBot.define do
  factory :user_height_assessment, class: "Assessments::UserHeightAssessment" do
    association :inspection

    # Leave most fields nil by default to allow tests to control completion percentage
    containing_wall_height { nil }
    platform_height { nil }
    tallest_user_height { nil }
    users_at_1000mm { nil }
    users_at_1200mm { nil }
    users_at_1500mm { nil }
    users_at_1800mm { nil }
    play_area_length { nil }
    play_area_width { nil }
    negative_adjustment { nil }

    trait :complete do
      containing_wall_height { 1.2 }
      platform_height { 1.0 }
      tallest_user_height { 1.8 }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      play_area_length { 5.0 }
      play_area_width { 4.0 }
      negative_adjustment { 0.0 }
      containing_wall_height_comment { "Wall height adequate for age group" }
      platform_height_comment { "Platform height meets standards" }
      tallest_user_height_comment { "User height appropriate" }
      play_area_length_comment { "Length meets capacity requirements" }
      play_area_width_comment { "Width adequate for user count" }
      negative_adjustment_comment { "No negative adjustments required" }
      permanent_roof_comment { "Roof structure appropriate" }
      # Pass/fail fields required for complete? to return true
      height_requirements_pass { true }
      permanent_roof_pass { true }
      user_capacity_pass { true }
      play_area_pass { true }
      negative_adjustments_pass { true }
    end

    trait :incomplete do
      containing_wall_height { nil }
      platform_height { nil }
    end

    # Common test scenario traits
    trait :standard_test_values do
      containing_wall_height { 2.5 }
      platform_height { 1.0 }
      tallest_user_height { 1.8 }
      permanent_roof { true }
      users_at_1000mm { 5 }
      users_at_1200mm { 4 }
      users_at_1500mm { 3 }
      users_at_1800mm { 2 }
      play_area_length { 10.0 }
      play_area_width { 8.0 }
      negative_adjustment { 2.0 }
      tallest_user_height_comment { "Test assessment comment" }
    end

    trait :with_basic_data do
      containing_wall_height { 1.5 }
      platform_height { 1.0 }
      tallest_user_height { 1.2 }
      permanent_roof { false }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      play_area_length { 5.0 }
      play_area_width { 4.0 }
      # Include pass/fail fields for completeness
      height_requirements_pass { true }
      permanent_roof_pass { true }
      user_capacity_pass { true }
      play_area_pass { true }
      negative_adjustments_pass { true }
    end

    trait :extreme_values do
      containing_wall_height { 999.999999 }
      platform_height { 0.000001 }
      tallest_user_height { 1.23456789 }
      play_area_length { 999999.123456 }
      play_area_width { 0.000000001 }
    end

    trait :edge_case_values do
      containing_wall_height { nil }
      platform_height { "" }
      tallest_user_height { 0 }
      users_at_1000mm { nil }
      users_at_1200mm { 0 }
    end
  end
end