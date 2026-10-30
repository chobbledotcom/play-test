# typed: false
# frozen_string_literal: true

module SeedData
  module InflatableGame
    def self.fields(passed: true)
      {
        maximum_users: 4,
        max_user_mass: 120,
        minimum_age: 1,
        maximum_age: 16,
        game_type: "Standard inflatable obstacle course",
        max_user_mass_pass: Shared.outcome(passed),
        age_range_marking_pass: Shared.outcome(passed),
        constant_air_flow_pass: Shared.outcome(passed),
        design_risk_pass: Shared.outcome(passed),
        intended_play_risk_pass: Shared.outcome(passed),
        ancillary_equipment_pass: Shared.outcome(passed),
        ancillary_equipment_compliant_pass: Shared.outcome(passed),
        containing_wall_height: rand(1.0..2.0).round(2),
        containing_wall_height_pass: Shared.outcome(passed)
      }.merge(comments(passed))
    end

    def self.comments(passed)
      {
        max_user_mass_comment: passed ? Shared::OK : Shared::FAIL,
        age_range_marking_comment: passed ? Shared::OK : Shared::FAIL,
        constant_air_flow_comment: passed ? Shared::PASS : Shared::FAIL,
        design_risk_comment: passed ? Shared::PASS : Shared::FAIL,
        intended_play_risk_comment: passed ? Shared::PASS : Shared::FAIL,
        ancillary_equipment_comment: passed ? Shared::OK : Shared::FAIL,
        ancillary_equipment_compliant_comment: passed ?
          Shared::OK :
          Shared::FAIL,
        containing_wall_height_comment: passed ? Shared::OK : Shared::FAIL
      }
    end
  end
end
