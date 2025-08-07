# frozen_string_literal: true

# This module provides field mappings for assessments
# Used by both seeds and tests to ensure consistency
module SeedData
  def self.check_passed?(inspection_passed)
    return true if inspection_passed

    rand < 0.9
  end

  def self.check_passed_integer?(inspection_passed)
    return :pass if inspection_passed

    (rand < 0.9) ? :pass : :fail
  end

  def self.user_fields
    {
      email: "test#{SecureRandom.hex(8)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User #{SecureRandom.hex(4)}",
      rpii_inspector_number: nil # Optional field
    }
  end

  def self.unit_fields
    {
      name: "Bouncy Castle #{%w[Mega Super Fun Party Adventure].sample} #{SecureRandom.hex(4)}",
      serial: "BC-#{Date.current.year}-#{SecureRandom.hex(4).upcase}",
      manufacturer: ["ABC Inflatables", "XYZ Bounce Co", "Fun Factory", "Party Products Ltd"].sample,
      operator: ["Rental Company #{SecureRandom.hex(2)}", "Party Hire #{SecureRandom.hex(2)}", "Events Ltd #{SecureRandom.hex(2)}"].sample,
      manufacture_date: Date.current - rand(365..1825).days,
      description: "Commercial grade inflatable bouncy castle suitable for events"
    }
  end

  def self.inspection_fields(passed: true)
    {
      inspection_date: Date.current,
      unique_report_number: "RPT-#{Date.current.year}-#{SecureRandom.hex(12)}",
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
      risk_assessment: "Low risk - all safety features functional and tested"
    }
  end
end
