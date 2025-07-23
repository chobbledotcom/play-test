FactoryBot.define do
  factory :user_height_assessment, class: "Assessments::UserHeightAssessment" do
    association :inspection

    containing_wall_height { nil }
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
      containing_wall_height_comment { "Wall height adequate for age group" }
      tallest_user_height { 1.8 }
      tallest_user_height_comment { "User height appropriate" }
      play_area_length { 5.0 }
      play_area_length_comment { "Length meets capacity requirements" }
      play_area_width { 4.0 }
      play_area_width_comment { "Width adequate for user count" }
      negative_adjustment { 0.0 }
      negative_adjustment_comment { "No negative adjustments required" }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
    end

    trait :incomplete do
      containing_wall_height { nil }
    end

    trait :standard_test_values do
      containing_wall_height { 2.5 }
      tallest_user_height { 1.8 }
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
      tallest_user_height { 1.2 }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      play_area_length { 5.0 }
      play_area_width { 4.0 }
      negative_adjustment { 0.0 }
    end

    trait :extreme_values do
      containing_wall_height { 999.999999 }
      tallest_user_height { 1.23456789 }
      play_area_length { 999999.123456 }
      play_area_width { 0.000000001 }
    end

    trait :edge_case_values do
      containing_wall_height { nil }
      tallest_user_height { 0 }
      users_at_1000mm { nil }
      users_at_1200mm { 0 }
    end
  end
end
