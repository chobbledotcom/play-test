FactoryBot.define do
  factory :user_height_assessment do
    association :inspection

    # Leave most fields nil by default to allow tests to control completion percentage
    containing_wall_height { nil }
    platform_height { nil }
    user_height { nil }
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
      user_height { 1.8 }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      play_area_length { 5.0 }
      play_area_width { 4.0 }
      negative_adjustment { 0.0 }
    end

    trait :incomplete do
      containing_wall_height { nil }
      platform_height { nil }
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

    trait :passed do
      # Structure assessment fields would be added here when defined
    end

    trait :failed do
      # Failed structure assessment
    end
  end

  factory :anchorage_assessment do
    association :inspection

    trait :passed do
      # Anchorage assessment fields would be added here when defined
    end

    trait :failed do
      # Failed anchorage assessment
    end
  end

  factory :materials_assessment do
    association :inspection

    trait :passed do
      # Materials assessment fields would be added here when defined
    end

    trait :failed do
      # Failed materials assessment
    end
  end

  factory :fan_assessment do
    association :inspection

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

    trait :passed do
      blower_flap_pass { true }
      blower_finger_pass { true }
      pat_pass { true }
      blower_visual_pass { true }
    end

    trait :failed do
      blower_flap_pass { false }
      blower_finger_pass { false }
      pat_pass { false }
      blower_visual_pass { false }
      blower_flap_comment { "Flap does not open properly" }
      blower_finger_comment { "Finger guards damaged" }
      pat_comment { "PAT test failed" }
      blower_visual_comment { "Visible damage to housing" }
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
