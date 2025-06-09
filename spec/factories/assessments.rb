FactoryBot.define do
  factory :user_height_assessment do
    association :inspection

    # Leave most fields nil by default to allow tests to control completion percentage
    containing_wall_height { nil }
    platform_height { nil }
    tallest_user_height { nil }
    users_at_1000mm { nil }
    users_at_1200mm { nil }
    users_at_1500mm { nil }
    users_at_1800mm { nil }
    play_area_length { nil }
    play_area_width { nil }
    negative_adjustment { nil }

    trait :complete do
      containing_wall_height { 1.2 }
      platform_height { 1.0 }
      tallest_user_height { 1.8 }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      play_area_length { 5.0 }
      play_area_width { 4.0 }
      negative_adjustment { 0.0 }
      containing_wall_height_comment { "Wall height adequate for age group" }
      platform_height_comment { "Platform height meets standards" }
      tallest_user_height_comment { "User height appropriate" }
      play_area_length_comment { "Length meets capacity requirements" }
      play_area_width_comment { "Width adequate for user count" }
      negative_adjustment_comment { "No negative adjustments required" }
      permanent_roof_comment { "Roof structure appropriate" }
    end

    trait :incomplete do
      containing_wall_height { nil }
      platform_height { nil }
    end

    # Common test scenario traits
    trait :standard_test_values do
      containing_wall_height { 2.5 }
      platform_height { 1.0 }
      tallest_user_height { 1.8 }
      permanent_roof { true }
      users_at_1000mm { 5 }
      users_at_1200mm { 4 }
      users_at_1500mm { 3 }
      users_at_1800mm { 2 }
      play_area_length { 10.0 }
      play_area_width { 8.0 }
      negative_adjustment { 2.0 }
      tallest_user_height_comment { "Test assessment comment" }
    end

    trait :with_basic_data do
      containing_wall_height { 1.5 }
      platform_height { 1.0 }
      tallest_user_height { 1.2 }
      permanent_roof { false }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      play_area_length { 5.0 }
      play_area_width { 4.0 }
    end

    trait :extreme_values do
      containing_wall_height { 999.999999 }
      platform_height { 0.000001 }
      tallest_user_height { 1.23456789 }
      play_area_length { 999999.123456 }
      play_area_width { 0.000000001 }
    end

    trait :edge_case_values do
      containing_wall_height { nil }
      platform_height { "" }
      tallest_user_height { 0 }
      users_at_1000mm { nil }
      users_at_1200mm { 0 }
    end
  end

  factory :slide_assessment do
    association :inspection

    # Minimal defaults to allow tests to control values
    slide_platform_height { nil }
    slide_wall_height { nil }
    runout_value { nil }
    slide_first_metre_height { nil }
    slide_beyond_first_metre_height { nil }
    clamber_netting_pass { nil }
    runout_pass { nil }
    slip_sheet_pass { nil }

    trait :complete do
      slide_platform_height { 2.0 }
      slide_wall_height { 1.8 }
      runout_value { 3.0 }
      slide_first_metre_height { 0.5 }
      slide_beyond_first_metre_height { 0.3 }
      clamber_netting_pass { true }
      runout_pass { true }
      slip_sheet_pass { true }
      slide_platform_height_comment { "Platform height appropriate for age group" }
      slide_wall_height_comment { "Wall height meets safety requirements" }
      slide_first_metre_height_comment { "First metre height compliant" }
      slide_beyond_first_metre_height_comment { "Height beyond first metre appropriate" }
      slide_permanent_roof_comment { "Roof structure evaluated" }
      clamber_netting_comment { "Netting in good condition" }
      runout_comment { "Runout distance adequate" }
      slip_sheet_comment { "Slip sheet properly installed" }
    end

    trait :failed do
      clamber_netting_pass { false }
      runout_pass { false }
    end

    trait :incomplete do
      slide_platform_height { nil }
      runout_value { nil }
    end
  end

  factory :structure_assessment do
    association :inspection

    # Critical safety checks (defaults to nil for tests to control)
    seam_integrity_pass { nil }
    lock_stitch_pass { nil }
    air_loss_pass { nil }
    straight_walls_pass { nil }
    sharp_edges_pass { nil }
    unit_stable_pass { nil }

    # Measurements
    stitch_length { nil }
    unit_pressure_value { nil }
    blower_tube_length { nil }

    # Measurement pass/fail checks
    stitch_length_pass { nil }
    unit_pressure_pass { nil }
    blower_tube_length_pass { nil }

    trait :passed do
      seam_integrity_pass { true }
      lock_stitch_pass { true }
      air_loss_pass { true }
      straight_walls_pass { true }
      sharp_edges_pass { true }
      unit_stable_pass { true }
      stitch_length { 15.0 }
      unit_pressure_value { 2.5 }
      blower_tube_length { 1.5 }
      stitch_length_pass { true }
      unit_pressure_pass { true }
      blower_tube_length_pass { true }
      step_size_pass { true }
      fall_off_height_pass { true }
    end

    trait :complete do
      seam_integrity_pass { true }
      lock_stitch_pass { true }
      air_loss_pass { true }
      straight_walls_pass { true }
      sharp_edges_pass { true }
      unit_stable_pass { true }
      stitch_length { 15.0 }
      unit_pressure_value { 2.5 }
      blower_tube_length { 1.5 }
      stitch_length_pass { true }
      unit_pressure_pass { true }
      blower_tube_length_pass { true }
      step_size_pass { true }
      fall_off_height_pass { true }
      seam_integrity_comment { "Seams in good condition" }
      lock_stitch_comment { "Stitching secure" }
      stitch_length_comment { "Stitch length within specification" }
      air_loss_comment { "No significant air loss detected" }
      straight_walls_comment { "Walls straight and properly tensioned" }
      sharp_edges_comment { "No sharp edges found" }
      blower_tube_length_comment { "Tube length appropriate" }
      unit_stable_comment { "Unit stable during operation" }
      evacuation_time_comment { "Evacuation time acceptable" }
    end

    trait :failed do
      seam_integrity_pass { false }
      lock_stitch_pass { false }
      air_loss_pass { false }
      stitch_length { 10.0 }
      stitch_length_pass { false }
    end
  end

  factory :anchorage_assessment do
    association :inspection

    # Anchor counts (defaults to nil for tests to control)
    num_low_anchors { nil }
    num_high_anchors { nil }

    # Pass/fail assessments
    num_anchors_pass { nil }
    anchor_type_pass { nil }
    pull_strength_pass { nil }
    anchor_degree_pass { nil }
    anchor_accessories_pass { nil }

    trait :passed do
      num_low_anchors { 6 }
      num_high_anchors { 4 }
      num_anchors_pass { true }
      anchor_type_pass { true }
      pull_strength_pass { true }
      anchor_degree_pass { true }
      anchor_accessories_pass { true }
    end

    trait :complete do
      num_low_anchors { 6 }
      num_high_anchors { 4 }
      num_anchors_pass { true }
      anchor_type_pass { true }
      pull_strength_pass { true }
      anchor_degree_pass { true }
      anchor_accessories_pass { true }
      num_anchors_comment { "Adequate anchor count for unit size" }
      anchor_type_comment { "Appropriate anchor type for surface" }
      pull_strength_comment { "Pull strength meets requirements" }
      anchor_degree_comment { "Anchor angle within specification" }
      anchor_accessories_comment { "All anchor accessories present" }
    end

    trait :failed do
      num_low_anchors { 2 }
      num_high_anchors { 1 }
      num_anchors_pass { false }
      anchor_type_pass { false }
      pull_strength_pass { false }
      anchor_degree_pass { true }
      anchor_accessories_pass { true }
    end

    trait :critical_failures do
      anchor_type_pass { false }
      pull_strength_pass { false }
    end

    trait :insufficient_anchors do
      num_low_anchors { 1 }
      num_high_anchors { 1 }
      num_anchors_pass { false }
    end
  end

  factory :materials_assessment do
    association :inspection

    # Material specifications (defaults to nil for tests to control)
    rope_size { nil }
    rope_size_pass { nil }

    # Critical material checks
    fabric_pass { nil }
    fire_retardant_pass { nil }
    thread_pass { nil }

    # Additional material checks
    clamber_pass { nil }
    retention_netting_pass { nil }
    zips_pass { nil }
    windows_pass { nil }
    artwork_pass { nil }

    trait :passed do
      rope_size { 25.0 }
      rope_size_pass { true }
      fabric_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      clamber_pass { true }
      retention_netting_pass { true }
      zips_pass { true }
      windows_pass { true }
      artwork_pass { true }
    end

    trait :complete do
      rope_size { 25.0 }
      rope_size_pass { true }
      fabric_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      clamber_pass { true }
      retention_netting_pass { true }
      zips_pass { true }
      windows_pass { true }
      artwork_pass { true }
      rope_size_comment { "Rope diameter meets safety standards" }
      fabric_comment { "Fabric in good condition" }
      fire_retardant_comment { "Fire retardant treatment effective" }
      thread_comment { "Thread quality appropriate" }
    end

    trait :failed do
      rope_size { 10.0 }  # Below minimum
      rope_size_pass { false }
      fabric_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
      clamber_pass { false }
      retention_netting_pass { false }
    end

    trait :critical_failures do
      fabric_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
    end
  end

  factory :fan_assessment do
    association :inspection

    # Default to nil for tests to control values
    fan_size_comment { nil }
    blower_flap_pass { nil }
    blower_flap_comment { nil }
    blower_finger_pass { nil }
    blower_finger_comment { nil }
    pat_pass { nil }
    pat_comment { nil }
    blower_visual_pass { nil }
    blower_visual_comment { nil }
    blower_serial { nil }

    trait :passed do
      fan_size_comment { "Standard 2HP blower" }
      blower_flap_pass { true }
      blower_flap_comment { "Flap opens and closes properly" }
      blower_finger_pass { true }
      blower_finger_comment { "Finger guards in place and secure" }
      pat_pass { true }
      pat_comment { "PAT test completed successfully" }
      blower_visual_pass { true }
      blower_visual_comment { "Visual inspection shows good condition" }
      blower_serial { "BL123456" }
    end

    trait :complete do
      fan_size_comment { "Standard 2HP blower" }
      blower_flap_pass { true }
      blower_flap_comment { "Flap opens and closes properly" }
      blower_finger_pass { true }
      blower_finger_comment { "Finger guards in place and secure" }
      pat_pass { true }
      pat_comment { "PAT test completed successfully" }
      blower_visual_pass { true }
      blower_visual_comment { "Visual inspection shows good condition" }
      blower_serial { "BL123456" }
    end

    trait :failed do
      fan_size_comment { "2HP blower - safety issues identified" }
      blower_flap_pass { false }
      blower_finger_pass { false }
      pat_pass { false }
      blower_visual_pass { false }
      blower_flap_comment { "Flap does not open properly" }
      blower_finger_comment { "Finger guards damaged" }
      pat_comment { "PAT test failed" }
      blower_visual_comment { "Visible damage to housing" }
      blower_serial { "BL789012" }
    end

    trait :pat_failure do
      pat_pass { false }
      pat_comment { "Electrical safety test failed - immediate attention required" }
    end
  end

  factory :enclosed_assessment do
    association :inspection

    exit_number { 2 }
    exit_number_pass { true }
    exit_number_comment { "Adequate emergency exits" }
    exit_visible_pass { true }
    exit_visible_comment { "Exits clearly marked and visible" }

    trait :passed do
      exit_number { 2 }
      exit_number_pass { true }
      exit_visible_pass { true }
      exit_number_comment { "Adequate emergency exits" }
      exit_visible_comment { "Exits clearly marked and visible" }
    end

    trait :failed do
      exit_number { 1 }  # Still a valid number, but assessment failed
      exit_number_pass { false }
      exit_visible_pass { false }
      exit_number_comment { "Insufficient emergency exits for occupancy" }
      exit_visible_comment { "Exits not clearly marked" }
    end
  end
end
