# typed: false
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

  def self.anchorage_fields(passed: true)
    fields = {
      num_low_anchors: rand(6..12),
      num_high_anchors: rand(4..8),
      num_low_anchors_pass: check_passed?(passed),
      num_high_anchors_pass: check_passed?(passed),
      anchor_accessories_pass: check_passed?(passed),
      anchor_degree_pass: check_passed?(passed),
      anchor_type_pass: check_passed?(passed),
      pull_strength_pass: check_passed?(passed)
    }

    fields[:anchor_type_comment] = "Some wear visible on anchor points" unless passed

    fields
  end

  def self.structure_fields(passed: true)
    structure_pass_fields(passed)
      .merge(structure_numeric_fields)
      .merge(structure_comments(passed))
  end

  def self.materials_fields(passed: true)
    {
      ropes: rand(18..45),
      ropes_pass: check_passed_integer?(passed),
      retention_netting_pass: check_passed_integer?(passed),
      zips_pass: check_passed_integer?(passed),
      windows_pass: check_passed_integer?(passed),
      artwork_pass: check_passed_integer?(passed),
      thread_pass: check_passed?(passed),
      fabric_strength_pass: check_passed?(passed),
      fire_retardant_pass: check_passed?(passed)
    }.merge(materials_comments(passed))
  end

  def self.fan_fields(passed: true)
    {
      blower_flap_pass: check_passed_integer?(passed),
      blower_finger_pass: check_passed?(passed),
      blower_visual_pass: check_passed?(passed),
      pat_pass: check_passed_integer?(passed),
      blower_serial: "FAN-#{SecureRandom.hex(6).upcase}",
      number_of_blowers: 1,
      blower_tube_length: rand(2.0..5.0).round(1),
      blower_tube_length_pass: check_passed?(passed)
    }.merge(fan_comments(passed))
  end

  def self.user_height_fields(passed: true)
    {
      containing_wall_height: rand(1.0..2.0).round(1),
      users_at_1000mm: rand(0..5),
      users_at_1200mm: rand(2..8),
      users_at_1500mm: rand(4..10),
      users_at_1800mm: rand(2..6),
      custom_user_height_comment: "Sample custom height comments",
      play_area_length: rand(3.0..10.0).round(1),
      play_area_width: rand(3.0..8.0).round(1),
      negative_adjustment: rand(0..2.0).round(1),
      containing_wall_height_comment: "Measured from base to top of wall",
      play_area_length_comment: "Effective play area after deducting obstacles",
      play_area_width_comment: "Width measured at narrowest point"
    }
  end

  def self.slide_fields(passed: true)
    platform_height = rand(2.0..6.0).round(1)
    required_runout = EN14960.calculate_slide_runout(platform_height).value
    runout = calculate_slide_runout(required_runout, passed)

    {
      slide_platform_height: platform_height,
      slide_wall_height: rand(1.0..2.0).round(1),
      runout: runout,
      slide_first_metre_height: rand(0.3..0.8).round(1),
      slide_beyond_first_metre_height: rand(0.8..1.5).round(1),
      clamber_netting_pass: check_passed_integer?(passed),
      runout_pass: check_passed?(passed),
      slip_sheet_pass: check_passed?(passed),
      slide_permanent_roof: false
    }.merge(slide_comments(passed))
  end

  def self.enclosed_fields(passed: true)
    {
      exit_number: rand(1..3),
      exit_number_pass: check_passed?(passed),
      exit_sign_always_visible_pass: check_passed?(passed),
      exit_number_comment: if passed
                             "Number of exits compliant with unit size"
                           else
                             "Additional exit required"
                           end,
      exit_sign_always_visible_comment: if passed
                                          "Exit signs visible from all points"
                                        else
                                          "Exit signs obscured from some angles"
                                        end
    }
  end

  def self.structure_pass_fields(passed)
    {
      seam_integrity_pass: check_passed?(passed),
      air_loss_pass: check_passed?(passed),
      straight_walls_pass: check_passed?(passed),
      sharp_edges_pass: check_passed?(passed),
      unit_stable_pass: check_passed?(passed),
      stitch_length_pass: check_passed?(passed),
      step_ramp_size_pass: check_passed?(passed),
      platform_height_pass: check_passed?(passed),
      critical_fall_off_height_pass: check_passed?(passed),
      unit_pressure_pass: check_passed?(passed),
      trough_pass: check_passed?(passed),
      entrapment_pass: check_passed?(passed),
      markings_pass: check_passed?(passed),
      grounding_pass: check_passed?(passed),
      evacuation_time_pass: check_passed?(passed)
    }
  end

  def self.structure_numeric_fields
    {
      unit_pressure: rand(1.0..3.0).round(1),
      step_ramp_size: rand(200..400),
      platform_height: rand(500..1500),
      critical_fall_off_height: rand(500..2000),
      trough_depth: rand(30..80),
      trough_adjacent_panel_width: rand(300..1000)
    }
  end

  def self.structure_comments(passed)
    {
      seam_integrity_comment: passed ? "All seams in good condition" : "Minor thread loosening noted",
      stitch_length_comment: "Measured at regular intervals",
      platform_height_comment: "Platform height acceptable for age group"
    }
  end

  def self.materials_comments(passed)
    if passed
      {fabric_strength_comment: "Fabric in good condition"}
    else
      {ropes_comment: "Rope shows signs of wear", fabric_strength_comment: "Minor surface wear noted"}
    end
  end

  def self.fan_comments(passed)
    expiry_date = (Date.current + 6.months).strftime("%B %Y")
    {
      fan_size_type: passed ? "Fan operating correctly at optimal pressure" : "Fan requires servicing",
      blower_flap_comment: passed ? "Flap mechanism functioning correctly" : "Flap sticking occasionally",
      blower_finger_comment: passed ? "Guard secure, no finger trap hazards" : "Guard needs tightening",
      blower_visual_comment: passed ? "Visual inspection satisfactory" : "Some wear visible on housing",
      pat_comment: passed ? "PAT test valid until #{expiry_date}" : "PAT test overdue"
    }
  end

  def self.calculate_slide_runout(required_runout, passed)
    if passed
      (required_runout + rand(0.5..1.5)).round(1)
    else
      (required_runout - rand(0.1..0.3))
    end
  end

  def self.slide_comments(passed)
    {
      slide_platform_height_comment: passed ? "Platform height compliant with EN 14960:2019" : "Platform height exceeds recommended limits",
      slide_wall_height_comment: "Wall height measured from slide bed",
      runout_comment: passed ? "Runout area clear and adequate" : "Runout area needs extending",
      clamber_netting_comment: passed ? "Netting secure with no gaps" : "Some gaps in netting need attention",
      slip_sheet_comment: passed ? "Slip sheet in good condition" : "Slip sheet showing wear"
    }
  end
end
