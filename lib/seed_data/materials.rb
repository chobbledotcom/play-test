# typed: false
# frozen_string_literal: true

module SeedData
  module Materials
    def self.fields(passed: true)
      {
        ropes: rand(18..45),
        ropes_pass: Shared.check_passed_integer?(passed),
        retention_netting_pass: Shared.check_passed_integer?(passed),
        zips_pass: Shared.check_passed_integer?(passed),
        windows_pass: Shared.check_passed_integer?(passed),
        artwork_pass: Shared.check_passed_integer?(passed),
        thread_pass: Shared.check_passed?(passed),
        fabric_strength_pass: Shared.check_passed?(passed),
        fire_retardant_pass: Shared.check_passed?(passed)
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
