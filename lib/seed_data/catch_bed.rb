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
        max_user_mass_marking_pass: Shared.outcome(passed),
        arrest_pass: Shared.outcome(passed),
        matting_pass: Shared.outcome(passed),
        design_risk_pass: Shared.outcome(passed),
        intended_play_pass: Shared.outcome(passed),
        ancillary_fit_pass: Shared.outcome(passed),
        ancillary_compliant_pass: Shared.outcome(passed),
        apron_pass: Shared.outcome(passed),
        trough_pass: Shared.outcome(passed),
        framework_pass: Shared.outcome(passed),
        grounding_pass: Shared.outcome(passed)
      }
    end

    def self.measurements(passed)
      {
        maximum_users: 4,
        max_user_mass_marking: 120,
        bed_height: rand(400..600),
        bed_height_pass: Shared.outcome(passed),
        platform_fall_distance: rand(0.8..1.5).round(2),
        platform_fall_distance_pass: Shared.outcome(passed),
        blower_tube_length: rand(2.5..4.0).round(2),
        blower_tube_length_pass: Shared.outcome(passed)
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
