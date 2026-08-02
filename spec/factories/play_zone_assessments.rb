# typed: false

FactoryBot.define do
  factory :play_zone_assessment, class: "Assessments::PlayZoneAssessment" do
    association :inspection

    # Pass/fail assessments
    age_marking_pass { nil }
    height_marking_pass { nil }
    sight_line_pass { nil }
    access_pass { nil }
    suitable_matting_pass { nil }
    traffic_flow_pass { nil }
    air_juggler_pass { nil }
    balls_pass { nil }
    ball_pool_gaps_pass { nil }
    fitted_sheet_pass { nil }
    ball_pool_depth_pass { nil }
    ball_pool_entry_height_pass { nil }
    slide_gradient_pass { nil }
    slide_platform_height_pass { nil }

    # Measurements
    ball_pool_depth { nil }
    ball_pool_entry_height { nil }
    slide_gradient { nil }
    slide_platform_height { nil }

    trait :passed do
      age_marking_pass { true }
      height_marking_pass { true }
      sight_line_pass { true }
      access_pass { true }
      suitable_matting_pass { true }
      traffic_flow_pass { true }
      air_juggler_pass { true }
      balls_pass { true }
      ball_pool_gaps_pass { true }
      fitted_sheet_pass { true }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { true }
      ball_pool_entry_height { 600 }
      ball_pool_entry_height_pass { true }
      slide_gradient { 50 }
      slide_gradient_pass { true }
      slide_platform_height { 1.2 }
      slide_platform_height_pass { true }
    end

    trait :complete do
      age_marking_pass { true }
      age_marking_comment { SeedData::OK }
      height_marking_pass { true }
      height_marking_comment { SeedData::OK }
      sight_line_pass { true }
      sight_line_comment { SeedData::OK }
      access_pass { true }
      access_comment { SeedData::OK }
      suitable_matting_pass { true }
      suitable_matting_comment { SeedData::OK }
      traffic_flow_pass { true }
      traffic_flow_comment { SeedData::OK }
      air_juggler_pass { true }
      air_juggler_comment { SeedData::PASS }
      balls_pass { true }
      balls_comment { SeedData::PASS }
      ball_pool_gaps_pass { true }
      ball_pool_gaps_comment { SeedData::OK }
      fitted_sheet_pass { true }
      fitted_sheet_comment { SeedData::OK }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { true }
      ball_pool_depth_comment { SeedData::OK }
      ball_pool_entry_height { 600 }
      ball_pool_entry_height_pass { true }
      ball_pool_entry_height_comment { SeedData::OK }
      slide_gradient { 50 }
      slide_gradient_pass { true }
      slide_gradient_comment { SeedData::OK }
      slide_platform_height { 1.2 }
      slide_platform_height_pass { true }
      slide_platform_height_comment { SeedData::OK }
    end

    trait :failed do
      age_marking_pass { false }
      height_marking_pass { false }
      sight_line_pass { true }
      access_pass { true }
      suitable_matting_pass { true }
      traffic_flow_pass { false }
      air_juggler_pass { true }
      balls_pass { false }
      ball_pool_gaps_pass { false }
      fitted_sheet_pass { true }
      ball_pool_depth { 500 }
      ball_pool_depth_pass { false }
      ball_pool_entry_height { 700 }
      ball_pool_entry_height_pass { false }
      slide_gradient { 70 }
      slide_gradient_pass { false }
      slide_platform_height { 2.0 }
      slide_platform_height_pass { false }
    end
  end
end
