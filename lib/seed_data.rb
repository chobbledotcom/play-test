# typed: false
# frozen_string_literal: true

module SeedData
  PASS = "Pass"
  FAIL = "Fail"
  GOOD = "Good"
  WEAR = "Wear"
  OK = "OK"

  def self.pass_fail_fields(passed, *fields)
    fields.to_h { |field| [field, passed ? PASS : FAIL] }
  end

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
      name: "Castle #{SecureRandom.hex(4)}",
      serial: "BC-#{Date.current.year}-#{SecureRandom.hex(4).upcase}",
      manufacturer: "Test Mfg",
      operator: "Test Op",
      manufacture_date: Date.current - rand(365..1825).days,
      description: "Test unit"
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
      risk_assessment: PASS
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

    fields[:anchor_type_comment] = WEAR unless passed

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
      custom_user_height_comment: OK,
      play_area_length: rand(3.0..10.0).round(1),
      play_area_width: rand(3.0..8.0).round(1),
      negative_adjustment: rand(0..2.0).round(1),
      containing_wall_height_comment: OK,
      play_area_length_comment: OK,
      play_area_width_comment: OK
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
      exit_sign_always_visible_pass: check_passed?(passed)
    }.merge(
      pass_fail_fields(
        passed,
        :exit_number_comment,
        :exit_sign_always_visible_comment
      )
    )
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
      seam_integrity_comment: passed ? GOOD : WEAR,
      stitch_length_comment: OK,
      platform_height_comment: OK
    }
  end

  def self.materials_comments(passed)
    passed ? {fabric_strength_comment: GOOD} : {
      ropes_comment: WEAR,
      fabric_strength_comment: WEAR
    }
  end

  def self.fan_comments(passed)
    expiry = (Date.current + 6.months).strftime("%B %Y")
    pass_fail_fields(
      passed,
      :fan_size_type,
      :blower_flap_comment,
      :blower_finger_comment,
      :blower_visual_comment
    ).merge(pat_comment: passed ? "Valid #{expiry}" : "Overdue")
  end

  def self.calculate_slide_runout(required_runout, passed)
    if passed
      (required_runout + rand(0.5..1.5)).round(1)
    else
      (required_runout - rand(0.1..0.3))
    end
  end

  def self.slide_comments(passed)
    pass_fail_fields(
      passed,
      :slide_platform_height_comment,
      :runout_comment,
      :clamber_netting_comment
    ).merge(
      slide_wall_height_comment: OK,
      slip_sheet_comment: passed ? GOOD : WEAR
    )
  end

  def self.pat_fields(passed: true)
    pat_numeric_fields
      .merge(pat_pass_fields(passed))
      .merge(pat_comments(passed))
  end

  def self.pat_numeric_fields
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

  def self.pat_pass_fields(passed)
    {
      equipment_class_pass: check_passed?(passed),
      visual_pass: check_passed?(passed),
      appliance_plug_check_pass: check_passed?(passed),
      fuse_rating_pass: check_passed?(passed),
      earth_ohms_pass: check_passed?(passed),
      insulation_mohms_pass: check_passed?(passed),
      leakage_ma_pass: check_passed?(passed),
      load_test_pass: check_passed?(passed),
      rcd_trip_time_ms_pass: check_passed?(passed)
    }
  end

  def self.pat_comments(passed)
    {
      equipment_class_comment: passed ? OK : FAIL,
      equipment_power_comment: passed ? OK : FAIL,
      visual_comment: passed ? GOOD : WEAR,
      appliance_plug_check_comment: passed ? GOOD : WEAR,
      fuse_rating_comment: passed ? OK : FAIL,
      earth_ohms_comment: passed ? OK : FAIL,
      insulation_mohms_comment: passed ? OK : FAIL,
      leakage_ma_comment: passed ? OK : FAIL,
      load_test_comment: passed ? GOOD : FAIL,
      rcd_trip_time_ms_comment: passed ? OK : FAIL
    }
  end
end
