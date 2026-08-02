# typed: false
# frozen_string_literal: true

module SeedData
  module CatchBed
    def self.fields(passed: true)
      pass_fields(passed)
        .merge(measurements(passed))
        .merge(comments(passed))
    end

    def self.pass_fields(passed)
      {
        type_of_unit: "Standard catch bed",
        max_user_mass_marking_pass: Shared.check_passed?(passed),
        arrest_pass: Shared.check_passed?(passed),
        matting_pass: Shared.check_passed?(passed),
        design_risk_pass: Shared.check_passed?(passed),
        intended_play_pass: Shared.check_passed?(passed),
        ancillary_fit_pass: Shared.check_passed?(passed),
        ancillary_compliant_pass: Shared.check_passed?(passed),
        apron_pass: Shared.check_passed?(passed),
        trough_pass: Shared.check_passed?(passed),
        framework_pass: Shared.check_passed?(passed),
        grounding_pass: Shared.check_passed?(passed)
      }
    end

    def self.measurements(passed)
      {
        bed_height: rand(400..600),
        bed_height_pass: Shared.check_passed?(passed),
        platform_fall_distance: rand(0.8..1.5).round(2),
        platform_fall_distance_pass: Shared.check_passed?(passed),
        blower_tube_length: rand(2.5..4.0).round(2),
        blower_tube_length_pass: Shared.check_passed?(passed)
      }
    end

    def self.comments(passed)
      Shared.generate_comments(passed, {
        max_user_mass_marking_comment: Shared::OK,
        arrest_comment: Shared::PASS,
        matting_comment: Shared::GOOD,
        design_risk_comment: Shared::PASS,
        intended_play_comment: Shared::PASS,
        ancillary_fit_comment: Shared::OK,
        ancillary_compliant_comment: Shared::OK,
        apron_comment: Shared::GOOD,
        trough_comment: Shared::OK,
        framework_comment: Shared::PASS,
        grounding_comment: Shared::PASS,
        bed_height_comment: Shared::OK,
        platform_fall_distance_comment: Shared::OK,
        blower_tube_length_comment: Shared::OK
      })
    end
  end
end
