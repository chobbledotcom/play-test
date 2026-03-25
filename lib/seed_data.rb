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

  def self.ball_pool_fields(passed: true)
    {
      age_range_marking_pass: check_passed?(passed),
      max_height_markings_pass: check_passed?(passed),
      suitable_matting_pass: check_passed?(passed),
      air_jugglers_compliant_pass: check_passed?(passed),
      balls_compliant_pass: check_passed?(passed),
      gaps_pass: check_passed?(passed),
      fitted_base_pass: check_passed?(passed),
      ball_pool_depth: rand(300..450),
      ball_pool_depth_pass: check_passed?(passed),
      ball_pool_entry: rand(500..630),
      ball_pool_entry_pass: check_passed?(passed)
    }.merge(ball_pool_comments(passed))
  end

  def self.ball_pool_comments(passed)
    {
      age_range_marking_comment: passed ? OK : FAIL,
      max_height_markings_comment: passed ? OK : FAIL,
      suitable_matting_comment: passed ? GOOD : FAIL,
      air_jugglers_compliant_comment: passed ? PASS : FAIL,
      balls_compliant_comment: passed ? PASS : FAIL,
      gaps_comment: passed ? OK : FAIL,
      fitted_base_comment: passed ? OK : FAIL,
      ball_pool_depth_comment: passed ? OK : FAIL,
      ball_pool_entry_comment: passed ? OK : FAIL
    }
  end

  def self.catch_bed_fields(passed: true)
    catch_bed_pass_fields(passed)
      .merge(catch_bed_measurements(passed))
      .merge(catch_bed_comments(passed))
  end

  def self.catch_bed_pass_fields(passed)
    {
      type_of_unit: "Standard catch bed",
      max_user_mass_marking_pass: check_passed?(passed),
      arrest_pass: check_passed?(passed),
      matting_pass: check_passed?(passed),
      design_risk_pass: check_passed?(passed),
      intended_play_pass: check_passed?(passed),
      ancillary_fit_pass: check_passed?(passed),
      ancillary_compliant_pass: check_passed?(passed),
      apron_pass: check_passed?(passed),
      trough_pass: check_passed?(passed),
      framework_pass: check_passed?(passed),
      grounding_pass: check_passed?(passed)
    }
  end

  def self.catch_bed_measurements(passed)
    {
      bed_height: rand(400..600),
      bed_height_pass: check_passed?(passed),
      platform_fall_distance: rand(0.8..1.5).round(2),
      platform_fall_distance_pass: check_passed?(passed),
      blower_tube_length: rand(2.5..4.0).round(2),
      blower_tube_length_pass: check_passed?(passed)
    }
  end

  def self.catch_bed_comments(passed)
    {
      max_user_mass_marking_comment: passed ? OK : FAIL,
      arrest_comment: passed ? PASS : FAIL,
      matting_comment: passed ? GOOD : FAIL,
      design_risk_comment: passed ? PASS : FAIL,
      intended_play_comment: passed ? PASS : FAIL,
      ancillary_fit_comment: passed ? OK : FAIL,
      ancillary_compliant_comment: passed ? OK : FAIL,
      apron_comment: passed ? GOOD : FAIL,
      trough_comment: passed ? OK : FAIL,
      framework_comment: passed ? PASS : FAIL,
      grounding_comment: passed ? PASS : FAIL,
      bed_height_comment: passed ? OK : FAIL,
      platform_fall_distance_comment: passed ? OK : FAIL,
      blower_tube_length_comment: passed ? OK : FAIL
    }
  end

  def self.bungee_fields(passed: true)
    bungee_pass_fields(passed)
      .merge(bungee_measurements)
      .merge(bungee_comments(passed))
  end

  def self.bungee_pass_fields(passed)
    {
      blower_forward_distance_pass: check_passed?(passed),
      marking_max_mass_pass: check_passed?(passed),
      marking_min_height_pass: check_passed?(passed),
      pull_strength_pass: check_passed?(passed),
      cord_length_max_pass: check_passed?(passed),
      cord_diametre_min_pass: check_passed?(passed),
      two_stage_locking_pass: check_passed?(passed),
      baton_compliant_pass: check_passed?(passed),
      lane_width_max_pass: check_passed?(passed),
      rear_wall_pass: check_passed?(passed),
      side_wall_pass: check_passed?(passed),
      running_wall_pass: check_passed?(passed),
      harness_width_pass: check_passed?(passed)
    }
  end

  def self.bungee_measurements
    {
      harness_width: 200,
      num_of_cords: 2,
      rear_wall_thickness: 0.6,
      rear_wall_height: 1.8,
      side_wall_length: 1.5,
      side_wall_height: 1.7,
      running_wall_width: 0.45,
      running_wall_height: 0.9
    }
  end

  def self.bungee_comments(passed)
    {
      blower_forward_distance_comment: passed ? OK : FAIL,
      marking_max_mass_comment: passed ? OK : FAIL,
      marking_min_height_comment: passed ? OK : FAIL,
      pull_strength_comment: passed ? PASS : FAIL,
      cord_length_max_comment: passed ? OK : FAIL,
      cord_diametre_min_comment: passed ? OK : FAIL,
      two_stage_locking_comment: passed ? PASS : FAIL,
      baton_compliant_comment: passed ? PASS : FAIL,
      lane_width_max_comment: passed ? OK : FAIL,
      rear_wall_comment: passed ? OK : FAIL,
      side_wall_comment: passed ? OK : FAIL,
      running_wall_comment: passed ? OK : FAIL,
      harness_width_comment: passed ? OK : FAIL
    }
  end

  def self.inflatable_game_fields(passed: true)
    {
      game_type: "Standard inflatable obstacle course",
      max_user_mass_pass: check_passed?(passed),
      age_range_marking_pass: check_passed?(passed),
      constant_air_flow_pass: check_passed?(passed),
      design_risk_pass: check_passed?(passed),
      intended_play_risk_pass: check_passed?(passed),
      ancillary_equipment_pass: check_passed?(passed),
      ancillary_equipment_compliant_pass: check_passed?(passed),
      containing_wall_height: rand(1.0..2.0).round(2),
      containing_wall_height_pass: check_passed?(passed)
    }.merge(inflatable_game_comments(passed))
  end

  def self.inflatable_game_comments(passed)
    {
      max_user_mass_comment: passed ? OK : FAIL,
      age_range_marking_comment: passed ? OK : FAIL,
      constant_air_flow_comment: passed ? PASS : FAIL,
      design_risk_comment: passed ? PASS : FAIL,
      intended_play_risk_comment: passed ? PASS : FAIL,
      ancillary_equipment_comment: passed ? OK : FAIL,
      ancillary_equipment_compliant_comment: passed ? OK : FAIL,
      containing_wall_height_comment: passed ? OK : FAIL
    }
  end

  def self.play_zone_fields(passed: true)
    play_zone_pass_fields(passed)
      .merge(play_zone_measurements(passed))
      .merge(play_zone_comments(passed))
  end

  def self.play_zone_pass_fields(passed)
    {
      age_marking_pass: check_passed?(passed),
      height_marking_pass: check_passed?(passed),
      sight_line_pass: check_passed?(passed),
      access_pass: check_passed?(passed),
      suitable_matting_pass: check_passed?(passed),
      traffic_flow_pass: check_passed?(passed),
      air_juggler_pass: check_passed?(passed),
      balls_pass: check_passed?(passed),
      ball_pool_gaps_pass: check_passed?(passed),
      fitted_sheet_pass: check_passed?(passed)
    }
  end

  def self.play_zone_measurements(passed)
    {
      ball_pool_depth: rand(300..450),
      ball_pool_depth_pass: check_passed?(passed),
      ball_pool_entry_height: rand(500..630),
      ball_pool_entry_height_pass: check_passed?(passed),
      slide_gradient: rand(40..64),
      slide_gradient_pass: check_passed?(passed),
      slide_platform_height: rand(1.0..1.5).round(2),
      slide_platform_height_pass: check_passed?(passed)
    }
  end

  def self.play_zone_comments(passed)
    {
      age_marking_comment: passed ? OK : FAIL,
      height_marking_comment: passed ? OK : FAIL,
      sight_line_comment: passed ? OK : FAIL,
      access_comment: passed ? OK : FAIL,
      suitable_matting_comment: passed ? GOOD : FAIL,
      traffic_flow_comment: passed ? OK : FAIL,
      air_juggler_comment: passed ? PASS : FAIL,
      balls_comment: passed ? PASS : FAIL,
      ball_pool_gaps_comment: passed ? OK : FAIL,
      fitted_sheet_comment: passed ? OK : FAIL,
      ball_pool_depth_comment: passed ? OK : FAIL,
      ball_pool_entry_height_comment: passed ? OK : FAIL,
      slide_gradient_comment: passed ? OK : FAIL,
      slide_platform_height_comment: passed ? OK : FAIL
    }
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
