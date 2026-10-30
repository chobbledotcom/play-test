# typed: false
# frozen_string_literal: true

module SeedData
  module Shared
    PASS = "Pass"
    FAIL = "Fail"
    GOOD = "Good"
    WEAR = "Wear"
    OK = "OK"

    def self.pass_fail_fields(passed, *fields)
      fields.to_h { |field| [field, passed ? PASS : FAIL] }
    end

    def self.generate_comments(passed, field_mappings)
      field_mappings.transform_values { |v| passed ? v : FAIL }
    end

    def self.outcome(inspection_passed)
      return "pass" if inspection_passed

      (rand < 0.9) ? "pass" : "fail"
    end

    def self.user_fields
      {
        email: "test#{SecureRandom.hex(8)}@example.com",
        password: "password123",
        password_confirmation: "password123",
        name: "Test User #{SecureRandom.hex(4)}",
        rpii_inspector_number: nil
      }
    end

    def self.unit_fields
      {
        name: "Castle #{SecureRandom.hex(4)}",
        serial: "BC-#{Date.current.year}-#{SecureRandom.hex(4).upcase}",
        manufacturer: "Test Mfg",
        manufacture_date: Date.current - rand(365..1825).days,
        description: "Test unit"
      }
    end

    def self.inspection_fields(passed: true)
      {
        inspection_date: Date.current,
        operator: "Test Operator",
        is_totally_enclosed: [true, false].sample,
        has_slide: [true, false].sample,
        indoor_only: [true, false].sample,
        width: rand(4.0..8.0).round(1),
        length: rand(5.0..10.0).round(1),
        height: rand(3.0..6.0).round(1)
      }
    end

    def self.results_fields(passed: true)
      {
        passed: passed,
        risk_assessment: PASS
      }
    end

    def self.anchorage_fields(passed: true)
      fields = {
        bungee_side_area: rand(15.0..25.0).round(2),
        num_low_anchors: rand(6..12),
        num_high_anchors: rand(4..8),
        num_low_anchors_pass: outcome(passed),
        num_high_anchors_pass: outcome(passed),
        anchor_accessories_pass: outcome(passed),
        anchor_degree_pass: outcome(passed),
        anchor_type_pass: outcome(passed),
        pull_strength_pass: outcome(passed)
      }

      fields[:anchor_type_comment] = WEAR unless passed

      fields
    end
  end
end
