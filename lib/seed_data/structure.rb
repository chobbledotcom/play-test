# typed: false
# frozen_string_literal: true

module SeedData
  module Structure
    def self.fields(passed: true)
      pass_fields(passed)
        .merge(numeric_fields)
        .merge(comments(passed))
    end

    def self.pass_fields(passed)
      {
        seam_integrity_pass: Shared.check_passed?(passed),
        air_loss_pass: Shared.check_passed?(passed),
        straight_walls_pass: Shared.check_passed?(passed),
        sharp_edges_pass: Shared.check_passed?(passed),
        unit_stable_pass: Shared.check_passed?(passed),
        stitch_length_pass: Shared.check_passed?(passed),
        step_ramp_size_pass: Shared.check_passed_integer?(passed),
        platform_height_pass: Shared.check_passed_integer?(passed),
        critical_fall_off_height_pass: Shared.check_passed_integer?(passed),
        unit_pressure_pass: Shared.check_passed?(passed),
        trough_pass: Shared.check_passed_integer?(passed),
        entrapment_pass: Shared.check_passed?(passed),
        markings_pass: Shared.check_passed?(passed),
        grounding_pass: Shared.check_passed_integer?(passed),
        evacuation_time_pass: Shared.check_passed?(passed)
      }
    end

    def self.numeric_fields
      {
        unit_pressure: rand(1.0..3.0).round(1),
        step_ramp_size: rand(200..400),
        platform_height: rand(500..1500),
        critical_fall_off_height: rand(500..2000),
        trough_depth: rand(30..80),
        trough_adjacent_panel_width: rand(300..1000)
      }
    end

    def self.comments(passed)
      {
        seam_integrity_comment: passed ? Shared::GOOD : Shared::WEAR,
        stitch_length_comment: Shared::OK,
        platform_height_comment: Shared::OK
      }
    end
  end
end
