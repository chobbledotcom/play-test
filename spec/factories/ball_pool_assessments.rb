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
      age_range_marking_pass { true }
      max_height_markings_pass { true }
      suitable_matting_pass { true }
      air_jugglers_compliant_pass { true }
      balls_compliant_pass { true }
      gaps_pass { true }
      fitted_base_pass { true }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { true }
      ball_pool_entry { 600 }
      ball_pool_entry_pass { true }
    end

    trait :complete do
      age_range_marking_pass { true }
      age_range_marking_comment { SeedData::OK }
      max_height_markings_pass { true }
      max_height_markings_comment { SeedData::OK }
      suitable_matting_pass { true }
      suitable_matting_comment { SeedData::OK }
      air_jugglers_compliant_pass { true }
      air_jugglers_compliant_comment { SeedData::PASS }
      balls_compliant_pass { true }
      balls_compliant_comment { SeedData::PASS }
      gaps_pass { true }
      gaps_comment { SeedData::OK }
      fitted_base_pass { true }
      fitted_base_comment { SeedData::OK }
      ball_pool_depth { 400 }
      ball_pool_depth_pass { true }
      ball_pool_depth_comment { SeedData::OK }
      ball_pool_entry { 600 }
      ball_pool_entry_pass { true }
      ball_pool_entry_comment { SeedData::OK }
    end

    trait :failed do
      age_range_marking_pass { false }
      max_height_markings_pass { false }
      suitable_matting_pass { true }
      air_jugglers_compliant_pass { true }
      balls_compliant_pass { false }
      gaps_pass { false }
      fitted_base_pass { true }
      ball_pool_depth { 500 }
      ball_pool_depth_pass { false }
      ball_pool_entry { 700 }
      ball_pool_entry_pass { false }
    end
  end
end
