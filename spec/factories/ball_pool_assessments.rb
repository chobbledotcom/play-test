# typed: false

FactoryBot.define do
  factory :ball_pool_assessment, class: "Assessments::BallPoolAssessment" do
    association :inspection

    # Pass/fail assessments
    age_range_marking_pass { nil }
    max_height_markings_pass { nil }
    suitable_matting_pass { nil }
    air_jugglers_compliant_pass { nil }
    balls_compliant_pass { nil }
    gaps_pass { nil }
    fitted_base_pass { nil }
    ball_pool_depth_pass { nil }
    ball_pool_entry_pass { nil }

    # Measurements
    ball_pool_depth { nil }
    ball_pool_entry { nil }

    trait :passed do
      maximum_users { 4 }
      max_height_markings { 1 }
      minimum_age { 1 }
      maximum_age { 3 }
      age_range_marking_pass { "pass" }
      max_height_markings_pass { "pass" }
      suitable_matting_pass { "pass" }
      air_jugglers_compliant_pass { "pass" }
      balls_compliant_pass { "pass" }
      gaps_pass { "pass" }
      fitted_base_pass { "pass" }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { "pass" }
      ball_pool_entry { 600 }
      ball_pool_entry_pass { "pass" }
    end

    trait :complete do
      maximum_users { 4 }
      max_height_markings { 1 }
      minimum_age { 1 }
      maximum_age { 3 }
      age_range_marking_pass { "pass" }
      age_range_marking_comment { SeedData::OK }
      max_height_markings_pass { "pass" }
      max_height_markings_comment { SeedData::OK }
      suitable_matting_pass { "pass" }
      suitable_matting_comment { SeedData::OK }
      air_jugglers_compliant_pass { "pass" }
      air_jugglers_compliant_comment { SeedData::PASS }
      balls_compliant_pass { "pass" }
      balls_compliant_comment { SeedData::PASS }
      gaps_pass { "pass" }
      gaps_comment { SeedData::OK }
      fitted_base_pass { "pass" }
      fitted_base_comment { SeedData::OK }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { "pass" }
      ball_pool_depth_comment { SeedData::OK }
      ball_pool_entry { 600 }
      ball_pool_entry_pass { "pass" }
      ball_pool_entry_comment { SeedData::OK }
    end

    trait :failed do
      age_range_marking_pass { "fail" }
      max_height_markings_pass { "fail" }
      suitable_matting_pass { "pass" }
      air_jugglers_compliant_pass { "pass" }
      balls_compliant_pass { "fail" }
      gaps_pass { "fail" }
      fitted_base_pass { "pass" }
      ball_pool_depth { 500 }
      ball_pool_depth_pass { "fail" }
      ball_pool_entry { 700 }
      ball_pool_entry_pass { "fail" }
    end
  end
end
