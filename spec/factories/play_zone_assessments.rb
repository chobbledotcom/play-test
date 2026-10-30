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
      height_marking { 1 }
      minimum_age { 1 }
      maximum_age { 3 }
      age_marking_pass { "pass" }
      height_marking_pass { "pass" }
      sight_line_pass { "pass" }
      access_pass { "pass" }
      suitable_matting_pass { "pass" }
      traffic_flow_pass { "pass" }
      air_juggler_pass { "pass" }
      balls_pass { "pass" }
      ball_pool_gaps_pass { "pass" }
      fitted_sheet_pass { "pass" }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { "pass" }
      ball_pool_entry_height { 600 }
      ball_pool_entry_height_pass { "pass" }
      slide_gradient { 50 }
      slide_gradient_pass { "pass" }
      slide_platform_height { 1.2 }
      slide_platform_height_pass { "pass" }
    end

    trait :complete do
      height_marking { 1 }
      minimum_age { 1 }
      maximum_age { 3 }
      age_marking_pass { "pass" }
      age_marking_comment { SeedData::OK }
      height_marking_pass { "pass" }
      height_marking_comment { SeedData::OK }
      sight_line_pass { "pass" }
      sight_line_comment { SeedData::OK }
      access_pass { "pass" }
      access_comment { SeedData::OK }
      suitable_matting_pass { "pass" }
      suitable_matting_comment { SeedData::OK }
      traffic_flow_pass { "pass" }
      traffic_flow_comment { SeedData::OK }
      air_juggler_pass { "pass" }
      air_juggler_comment { SeedData::PASS }
      balls_pass { "pass" }
      balls_comment { SeedData::PASS }
      ball_pool_gaps_pass { "pass" }
      ball_pool_gaps_comment { SeedData::OK }
      fitted_sheet_pass { "pass" }
      fitted_sheet_comment { SeedData::OK }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { "pass" }
      ball_pool_depth_comment { SeedData::OK }
      ball_pool_entry_height { 600 }
      ball_pool_entry_height_pass { "pass" }
      ball_pool_entry_height_comment { SeedData::OK }
      slide_gradient { 50 }
      slide_gradient_pass { "pass" }
      slide_gradient_comment { SeedData::OK }
      slide_platform_height { 1.2 }
      slide_platform_height_pass { "pass" }
      slide_platform_height_comment { SeedData::OK }
    end

    trait :failed do
      age_marking_pass { "fail" }
      height_marking_pass { "fail" }
      sight_line_pass { "pass" }
      access_pass { "pass" }
      suitable_matting_pass { "pass" }
      traffic_flow_pass { "fail" }
      air_juggler_pass { "pass" }
      balls_pass { "fail" }
      ball_pool_gaps_pass { "fail" }
      fitted_sheet_pass { "pass" }
      ball_pool_depth { 500 }
      ball_pool_depth_pass { "fail" }
      ball_pool_entry_height { 700 }
      ball_pool_entry_height_pass { "fail" }
      slide_gradient { 70 }
      slide_gradient_pass { "fail" }
      slide_platform_height { 2.0 }
      slide_platform_height_pass { "fail" }
    end
  end
end
