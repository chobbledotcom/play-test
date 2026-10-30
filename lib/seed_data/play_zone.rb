# typed: false
# frozen_string_literal: true

module SeedData
  module PlayZone
    def self.fields(passed: true)
      pass_fields(passed)
        .merge(measurements(passed))
        .merge(comments(passed))
    end

    def self.pass_fields(passed)
      {
        age_marking_pass: Shared.outcome(passed),
        height_marking_pass: Shared.outcome(passed),
        sight_line_pass: Shared.outcome(passed),
        access_pass: Shared.outcome(passed),
        suitable_matting_pass: Shared.outcome(passed),
        traffic_flow_pass: Shared.outcome(passed),
        air_juggler_pass: Shared.outcome(passed),
        balls_pass: Shared.outcome(passed),
        ball_pool_gaps_pass: Shared.outcome(passed),
        fitted_sheet_pass: Shared.outcome(passed)
      }
    end

    def self.measurements(passed)
      {
        height_marking: 1,
        minimum_age: 1,
        maximum_age: 3,
        ball_pool_depth: rand(300..450),
        ball_pool_depth_pass: Shared.outcome(passed),
        ball_pool_entry_height: rand(500..630),
        ball_pool_entry_height_pass: Shared.outcome(passed),
        slide_gradient: rand(40..64),
        slide_gradient_pass: Shared.outcome(passed),
        slide_platform_height: rand(1.0..1.5).round(2),
        slide_platform_height_pass: Shared.outcome(passed)
      }
    end

    def self.comments(passed)
      Shared.generate_comments(passed, {
        age_marking_comment: Shared::OK,
        height_marking_comment: Shared::OK,
        sight_line_comment: Shared::OK,
        access_comment: Shared::OK,
        suitable_matting_comment: Shared::GOOD,
        traffic_flow_comment: Shared::OK,
        air_juggler_comment: Shared::PASS,
        balls_comment: Shared::PASS,
        ball_pool_gaps_comment: Shared::OK,
        fitted_sheet_comment: Shared::OK,
        ball_pool_depth_comment: Shared::OK,
        ball_pool_entry_height_comment: Shared::OK,
        slide_gradient_comment: Shared::OK,
        slide_platform_height_comment: Shared::OK
      })
    end
  end
end
