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
        age_marking_pass: Shared.check_passed?(passed),
        height_marking_pass: Shared.check_passed?(passed),
        sight_line_pass: Shared.check_passed?(passed),
        access_pass: Shared.check_passed?(passed),
        suitable_matting_pass: Shared.check_passed?(passed),
        traffic_flow_pass: Shared.check_passed?(passed),
        air_juggler_pass: Shared.check_passed?(passed),
        balls_pass: Shared.check_passed?(passed),
        ball_pool_gaps_pass: Shared.check_passed?(passed),
        fitted_sheet_pass: Shared.check_passed?(passed)
      }
    end

    def self.measurements(passed)
      {
        ball_pool_depth: rand(300..450),
        ball_pool_depth_pass: Shared.check_passed?(passed),
        ball_pool_entry_height: rand(500..630),
        ball_pool_entry_height_pass: Shared.check_passed?(passed),
        slide_gradient: rand(40..64),
        slide_gradient_pass: Shared.check_passed?(passed),
        slide_platform_height: rand(1.0..1.5).round(2),
        slide_platform_height_pass: Shared.check_passed?(passed)
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
