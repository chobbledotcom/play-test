# typed: false
# frozen_string_literal: true

module SeedData
  module Slide
    def self.fields(passed: true)
      platform_height = rand(2.0..6.0).round(1)
      required_runout = EN14960.calculate_slide_runout(platform_height).value
      runout = calculate_runout(required_runout, passed)

      {
        slide_platform_height: platform_height,
        slide_wall_height: rand(1.0..2.0).round(1),
        runout: runout,
        slide_first_metre_height: rand(0.3..0.8).round(1),
        slide_beyond_first_metre_height: rand(0.8..1.5).round(1),
        clamber_netting_pass: Shared.check_passed_integer?(passed),
        runout_pass: Shared.check_passed?(passed),
        slip_sheet_pass: Shared.check_passed?(passed),
        slide_permanent_roof: false
      }.merge(comments(passed))
    end

    def self.comments(passed)
      Shared.pass_fail_fields(
        passed,
        :slide_platform_height_comment,
        :runout_comment,
        :clamber_netting_comment
      ).merge(
        slide_wall_height_comment: Shared::OK,
        slip_sheet_comment: passed ? Shared::GOOD : Shared::WEAR
      )
    end

    def self.calculate_runout(required_runout, passed)
      if passed
        (required_runout + rand(0.5..1.5)).round(1)
      else
        (required_runout - rand(0.1..0.3))
      end
    end
  end
end
