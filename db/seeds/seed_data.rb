# This module provides field mappings for assessments
# Used by both seeds and tests to ensure consistency
module SeedData
  def self.check_passed?(inspection_passed)
    return true if inspection_passed

    rand < 0.9
  end

  def self.user_fields
    {
      email: "test#{rand(1000..9999)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User #{rand(1..99)}",
      rpii_inspector_number: nil  # Optional field
    }
  end

  def self.unit_fields
    {
      name: "Bouncy Castle #{["Mega", "Super", "Fun", "Party", "Adventure"].sample} #{rand(1..99)}",
      serial: "BC-#{Date.current.year}-#{SecureRandom.hex(4).upcase}",
      manufacturer: ["ABC Inflatables", "XYZ Bounce Co", "Fun Factory", "Party Products Ltd"].sample,
      owner: ["Rental Company #{rand(1..10)}", "Party Hire #{rand(1..5)}", "Events Ltd"].sample,
      manufacture_date: Date.current - rand(365..1825).days,
      description: "Commercial grade inflatable bouncy castle suitable for events"
    }
  end

  def self.inspection_fields(passed: true)
    {
      inspection_date: Date.current,
      inspection_location: "Test Location #{rand(1..5)}",
      unique_report_number: "RPT-#{Date.current.year}-#{rand(1000..9999)}",
      is_totally_enclosed: [true, false].sample,
      has_slide: [true, false].sample,
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
    {
      num_low_anchors: rand(6..12),
      num_high_anchors: rand(4..8),
      num_low_anchors_pass: check_passed?(passed),
      num_high_anchors_pass: check_passed?(passed),
      anchor_accessories_pass: check_passed?(passed),
      anchor_degree_pass: check_passed?(passed),
      anchor_type_pass: check_passed?(passed),
      pull_strength_pass: check_passed?(passed),
      anchor_type_comment: passed ? nil : "Some wear visible on anchor points"
    }
  end

  def self.structure_fields(passed: true)
    {
      seam_integrity_pass: check_passed?(passed),
      uses_lock_stitching_pass: check_passed?(passed),
      air_loss_pass: check_passed?(passed),
      straight_walls_pass: check_passed?(passed),
      sharp_edges_pass: check_passed?(passed),
      unit_stable_pass: check_passed?(passed),
      stitch_length_pass: check_passed?(passed),
      blower_tube_length_pass: check_passed?(passed),
      step_ramp_size_pass: check_passed?(passed),
      critical_fall_off_height_pass: check_passed?(passed),
      unit_pressure_pass: check_passed?(passed),
      trough_pass: check_passed?(passed),
      entrapment_pass: check_passed?(passed),
      markings_pass: check_passed?(passed),
      grounding_pass: check_passed?(passed),
      stitch_length: rand(8..12),
      unit_pressure: rand(1.0..3.0).round(1),
      blower_tube_length: rand(2.0..5.0).round(1),
      step_ramp_size: rand(200..400),
      critical_fall_off_height: rand(0.5..2.0).round(1),
      trough_depth: rand(0.1..0.5).round(1),
      trough_depth_pass: check_passed?(passed),
      trough_adjacent_panel_width: rand(0.3..1.0).round(1),
      trough_adjacent_panel_width_pass: check_passed?(passed),
      evacuation_time: rand(30..90),
      evacuation_time_pass: check_passed?(passed),
      seam_integrity_comment: passed ? "All seams in good condition" : "Minor thread loosening noted",
      uses_lock_stitching_comment: passed ? "Lock stitching intact throughout" : "Some lock stitching showing wear",
      stitch_length_comment: "Measured at regular intervals"
    }
  end

  def self.materials_fields(passed: true)
    {
      ropes: rand(18..45),
      ropes_pass: check_passed?(passed),
      clamber_netting_pass: check_passed?(passed),
      retention_netting_pass: check_passed?(passed),
      zips_pass: check_passed?(passed),
      windows_pass: check_passed?(passed),
      artwork_pass: check_passed?(passed),
      thread_pass: check_passed?(passed),
      fabric_strength_pass: check_passed?(passed),
      fire_retardant_pass: check_passed?(passed),
      ropes_comment: passed ? nil : "Rope shows signs of wear",
      fabric_strength_comment: passed ? "Fabric in good condition" : "Minor surface wear noted"
    }
  end

  def self.fan_fields(passed: true)
    {
      blower_flap_pass: check_passed?(passed),
      blower_finger_pass: check_passed?(passed),
      blower_visual_pass: check_passed?(passed),
      pat_pass: check_passed?(passed),
      blower_serial_pass: check_passed?(passed),
      blower_serial: "FAN-#{rand(1000..9999)}",
      fan_size_type: passed ? "Fan operating correctly at optimal pressure" : "Fan requires servicing",
      blower_flap_comment: passed ? "Flap mechanism functioning correctly" : "Flap sticking occasionally",
      blower_finger_comment: passed ? "Guard secure, no finger trap hazards" : "Guard needs tightening",
      blower_visual_comment: passed ? "Visual inspection satisfactory" : "Some wear visible on housing",
      pat_comment: passed ? "PAT test valid until #{(Date.current + 6.months).strftime("%B %Y")}" : "PAT test overdue",
      blower_serial_comment: passed ? "Serial number visible and recorded" : "Serial number partially obscured"
    }
  end

  def self.user_height_fields(passed: true)
    {
      containing_wall_height: rand(1.0..2.0).round(1),
      platform_height: rand(0.5..1.5).round(1),
      tallest_user_height: rand(1.2..1.8).round(1),
      users_at_1000mm: rand(0..5),
      users_at_1200mm: rand(2..8),
      users_at_1500mm: rand(4..10),
      users_at_1800mm: rand(2..6),
      play_area_length: rand(3.0..10.0).round(1),
      play_area_width: rand(3.0..8.0).round(1),
      negative_adjustment: rand(0..2.0).round(1),
      tallest_user_height_comment: passed ? "Capacity within safe limits based on EN 14960:2019" : "Review user capacity - exceeds recommended limits",
      containing_wall_height_comment: "Measured from base to top of wall",
      platform_height_comment: "Platform height acceptable for age group",
      play_area_length_comment: "Effective play area after deducting obstacles",
      play_area_width_comment: "Width measured at narrowest point"
    }
  end

  def self.slide_fields(passed: true)
    platform_height = rand(2.0..6.0).round(1)

    # Use the actual SafetyStandard calculation for consistency
    required_runout = SafetyStandard.calculate_required_runout(platform_height)

    runout = if passed
      (required_runout + rand(0.5..1.5)).round(1)
    else
      fail_margin = rand(0.1..0.3)
      (required_runout - fail_margin)
    end

    {
      slide_platform_height: platform_height,
      slide_wall_height: rand(1.0..2.0).round(1),
      runout: runout,
      slide_first_metre_height: rand(0.3..0.8).round(1),
      slide_beyond_first_metre_height: rand(0.8..1.5).round(1),
      clamber_netting_pass: check_passed?(passed),
      runout_pass: check_passed?(passed),
      slip_sheet_pass: check_passed?(passed),
      slide_permanent_roof: false,
      slide_platform_height_comment: passed ? "Platform height compliant with EN 14960:2019" : "Platform height exceeds recommended limits",
      slide_wall_height_comment: "Wall height measured from slide bed",
      runout_comment: passed ? "Runout area clear and adequate" : "Runout area needs extending",
      clamber_netting_comment: passed ? "Netting secure with no gaps" : "Some gaps in netting need attention",
      slip_sheet_comment: passed ? "Slip sheet in good condition" : "Slip sheet showing wear"
    }
  end

  def self.enclosed_fields(passed: true)
    {
      exit_number: rand(1..3),
      exit_number_pass: check_passed?(passed),
      exit_sign_always_visible_pass: check_passed?(passed),
      exit_number_comment: passed ? "Number of exits compliant with unit size" : "Additional exit required",
      exit_sign_always_visible_comment: passed ? "Exit signs visible from all points" : "Exit signs obscured from some angles"
    }
  end
end
