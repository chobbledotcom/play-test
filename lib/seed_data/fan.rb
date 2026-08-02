# typed: false
# frozen_string_literal: true

module SeedData
  module Fan
    def self.fields(passed: true)
      {
        blower_flap_pass: Shared.check_passed_integer?(passed),
        blower_finger_pass: Shared.check_passed?(passed),
        blower_visual_pass: Shared.check_passed?(passed),
        pat_pass: Shared.check_passed_integer?(passed),
        blower_serial: "FAN-#{SecureRandom.hex(6).upcase}",
        number_of_blowers: 1,
        blower_tube_length: rand(2.0..5.0).round(1),
        blower_tube_length_pass: Shared.check_passed?(passed)
      }.merge(comments(passed))
    end

    def self.comments(passed)
      expiry = (Date.current + 6.months).strftime("%B %Y")
      Shared.pass_fail_fields(
        passed,
        :fan_size_type,
        :blower_flap_comment,
        :blower_finger_comment,
        :blower_visual_comment
      ).merge(pat_comment: passed ? "Valid #{expiry}" : "Overdue")
    end
  end
end
