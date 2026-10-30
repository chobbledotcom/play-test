# typed: false
# frozen_string_literal: true

module SeedData
  module BallPool
    def self.fields(passed: true)
      {
        maximum_users: 4,
        max_height_markings: 1,
        minimum_age: 1,
        maximum_age: 3,
        age_range_marking_pass: Shared.outcome(passed),
        max_height_markings_pass: Shared.outcome(passed),
        suitable_matting_pass: Shared.outcome(passed),
        air_jugglers_compliant_pass: Shared.outcome(passed),
        balls_compliant_pass: Shared.outcome(passed),
        gaps_pass: Shared.outcome(passed),
        fitted_base_pass: Shared.outcome(passed),
        ball_pool_depth: rand(300..450),
        ball_pool_depth_pass: Shared.outcome(passed),
        ball_pool_entry: rand(500..630),
        ball_pool_entry_pass: Shared.outcome(passed)
      }.merge(comments(passed))
    end

    def self.comments(passed)
      Shared.generate_comments(passed, {
        age_range_marking_comment: Shared::OK,
        max_height_markings_comment: Shared::OK,
        suitable_matting_comment: Shared::GOOD,
        air_jugglers_compliant_comment: Shared::PASS,
        balls_compliant_comment: Shared::PASS,
        gaps_comment: Shared::OK,
        fitted_base_comment: Shared::OK,
        ball_pool_depth_comment: Shared::OK,
        ball_pool_entry_comment: Shared::OK
      })
    end
  end
end
