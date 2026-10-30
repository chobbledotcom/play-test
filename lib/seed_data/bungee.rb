# typed: false
# frozen_string_literal: true

module SeedData
  module Bungee
    def self.fields(passed: true)
      pass_fields(passed)
        .merge(measurements)
        .merge(comments(passed))
    end

    def self.pass_fields(passed)
      {
        blower_forward_distance_pass: Shared.outcome(passed),
        marking_max_mass_pass: Shared.outcome(passed),
        marking_min_height_pass: Shared.outcome(passed),
        pull_strength_pass: Shared.outcome(passed),
        cord_length_max_pass: Shared.outcome(passed),
        cord_diametre_min_pass: Shared.outcome(passed),
        two_stage_locking_pass: Shared.outcome(passed),
        baton_compliant_pass: Shared.outcome(passed),
        lane_width_max_pass: Shared.outcome(passed),
        rear_wall_pass: Shared.outcome(passed),
        side_wall_pass: Shared.outcome(passed),
        running_wall_pass: Shared.outcome(passed),
        harness_width_pass: Shared.outcome(passed)
      }
    end

    def self.measurements
      {
        maximum_users: 4,
        marking_max_mass: 120,
        marking_min_height: 1.2,
        pull_strength: 2500,
        harness_width: 200,
        num_of_cords: 2,
        rear_wall_thickness: 0.6,
        rear_wall_height: 1.8,
        side_wall_length: 1.5,
        side_wall_height: 1.7,
        running_wall_width: 0.45,
        running_wall_height: 0.9
      }
    end

    def self.comments(passed)
      Shared.generate_comments(passed, {
        blower_forward_distance_comment: Shared::OK,
        marking_max_mass_comment: Shared::OK,
        marking_min_height_comment: Shared::OK,
        pull_strength_comment: Shared::PASS,
        cord_length_max_comment: Shared::OK,
        cord_diametre_min_comment: Shared::OK,
        two_stage_locking_comment: Shared::PASS,
        baton_compliant_comment: Shared::PASS,
        lane_width_max_comment: Shared::OK,
        rear_wall_comment: Shared::OK,
        side_wall_comment: Shared::OK,
        running_wall_comment: Shared::OK,
        harness_width_comment: Shared::OK
      })
    end
  end
end
