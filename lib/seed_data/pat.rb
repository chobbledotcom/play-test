# typed: false
# frozen_string_literal: true

module SeedData
  module Pat
    def self.fields(passed: true)
      numeric_fields
        .merge(pass_fields(passed))
        .merge(comments(passed))
    end

    def self.numeric_fields
      {
        equipment_class: [1, 2].sample,
        equipment_power: rand(100..3000),
        fuse_rating: [3, 5, 13].sample,
        earth_ohms: rand(0.01..0.5).round(2),
        insulation_mohms: rand(100..500),
        leakage_ma: rand(0.1..2.0).round(2),
        rcd_trip_time_ms: rand(15.0..35.0).round(1)
      }
    end

    def self.pass_fields(passed)
      {
        equipment_class_pass: Shared.check_passed?(passed),
        visual_pass: Shared.check_passed?(passed),
        appliance_plug_check_pass: Shared.check_passed?(passed),
        fuse_rating_pass: Shared.check_passed?(passed),
        earth_ohms_pass: Shared.check_passed?(passed),
        insulation_mohms_pass: Shared.check_passed?(passed),
        leakage_ma_pass: Shared.check_passed?(passed),
        load_test_pass: Shared.check_passed?(passed),
        rcd_trip_time_ms_pass: Shared.check_passed?(passed)
      }
    end

    def self.comments(passed)
      {
        equipment_class_comment: passed ? Shared::OK : Shared::FAIL,
        equipment_power_comment: passed ? Shared::OK : Shared::FAIL,
        visual_comment: passed ? Shared::GOOD : Shared::WEAR,
        appliance_plug_check_comment: passed ? Shared::GOOD : Shared::WEAR,
        fuse_rating_comment: passed ? Shared::OK : Shared::FAIL,
        earth_ohms_comment: passed ? Shared::OK : Shared::FAIL,
        insulation_mohms_comment: passed ? Shared::OK : Shared::FAIL,
        leakage_ma_comment: passed ? Shared::OK : Shared::FAIL,
        load_test_comment: passed ? Shared::GOOD : Shared::FAIL,
        rcd_trip_time_ms_comment: passed ? Shared::OK : Shared::FAIL
      }
    end
  end
end
