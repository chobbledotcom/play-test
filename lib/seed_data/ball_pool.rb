# typed: false
# frozen_string_literal: true

module SeedData
  module BallPool
    def self.fields(passed: true)
      {
        age_range_marking_pass: Shared.check_passed?(passed),
        max_height_markings_pass: Shared.check_passed?(passed),
        suitable_matting_pass: Shared.check_passed?(passed),
        air_jugglers_compliant_pass: Shared.check_passed?(passed),
        balls_compliant_pass: Shared.check_passed?(passed),
        gaps_pass: Shared.check_passed?(passed),
        fitted_base_pass: Shared.check_passed?(passed),
        ball_pool_depth: rand(300..450),
        ball_pool_depth_pass: Shared.check_passed?(passed),
        ball_pool_entry: rand(500..630),
        ball_pool_entry_pass: Shared.check_passed?(passed)
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
