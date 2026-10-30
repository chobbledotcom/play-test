# typed: false
# frozen_string_literal: true

module SeedData
  module Materials
    def self.fields(passed: true)
      {
        ropes: rand(18..45),
        ropes_pass: Shared.outcome(passed),
        retention_netting_pass: Shared.outcome(passed),
        zips_pass: Shared.outcome(passed),
        windows_pass: Shared.outcome(passed),
        artwork_pass: Shared.outcome(passed),
        thread_pass: Shared.outcome(passed),
        fabric_strength_pass: Shared.outcome(passed),
        fire_retardant_pass: Shared.outcome(passed)
      }.merge(comments(passed))
    end

    def self.comments(passed)
      passed ? {fabric_strength_comment: Shared::GOOD} : {
        ropes_comment: Shared::WEAR,
        fabric_strength_comment: Shared::WEAR
      }
    end
  end
end
