FactoryBot.define do
  factory :unit do
    association :user
    sequence(:name) { |n| "Test Unit #{n}" }
    sequence(:serial) { |n| "TEST#{n.to_s.rjust(3, "0")}" }
    description { "Test Bounce House" }
    manufacturer { "Test Manufacturer" }
    has_slide { false }
    owner { "Test Owner" }
    width { 10.0 }
    length { 10.0 }
    height { 3.0 }
    model { "Test Model" }
    manufacture_date { 1.year.ago }
    notes { "Test notes" }

    trait :with_slide do
      has_slide { true }
      description { "Test Unit with Slide" }
      width { 3.0 }
      length { 8.0 }
      height { 2.0 }
      slide_platform_height { 1.8 }
      slide_wall_height { 1.5 }
      slide_first_metre_height { 1.0 }
      slide_beyond_first_metre_height { 0.8 }
      slide_permanent_roof { false }
      runout_value { 4.0 }
      slide_platform_height_comment { "Platform height suitable for age group" }
      slide_wall_height_comment { "Wall height meets safety requirements" }
      slide_first_metre_height_comment { "First metre height compliant" }
      slide_beyond_first_metre_height_comment { "Height beyond first metre appropriate" }
      slide_permanent_roof_comment { "No permanent roof structure" }
      runout_value_comment { "Adequate runout distance provided" }
    end

    trait :totally_enclosed do
      is_totally_enclosed { true }
      description { "Test Totally Enclosed Unit" }
      exit_number { 2 }
      exit_number_comment { "Two emergency exits provided" }
    end

    trait :with_slide_and_enclosed do
      has_slide { true }
      is_totally_enclosed { true }
      description { "Test Unit with Slide and Totally Enclosed" }
      width { 4.0 }
      length { 10.0 }
      height { 3.0 }
    end

    trait :with_comprehensive_dimensions do
      # Basic unit details
      name { "Complete Test Unit" }
      manufacturer { "Test Manufacturer" }
      model { "TM-2024" }
      serial { "TEST-SERIAL-001" }
      description { "A test unit with all fields populated" }
      owner { "Test Owner Ltd" }
      manufacture_date { Date.new(2024, 1, 15) }
      has_slide { true }
      is_totally_enclosed { true }
      notes { "Test notes for unit" }
      
      # Basic dimensions
      width { 12.5 }
      length { 10.0 }
      height { 4.5 }
      width_comment { "Width comment" }
      length_comment { "Length comment" }
      height_comment { "Height comment" }
      
      # Anchorage dimensions
      num_low_anchors { 6 }
      num_high_anchors { 2 }
      num_low_anchors_comment { "Low anchor comment" }
      num_high_anchors_comment { "High anchor comment" }
      
      # Structure dimensions
      stitch_length { 25.0 }
      evacuation_time { 45 }
      unit_pressure_value { 350.0 }
      blower_tube_length { 12.0 }
      step_size_value { 1.5 }
      fall_off_height_value { 2.0 }
      trough_depth_value { 0.8 }
      trough_width_value { 1.2 }
      
      # Slide dimensions
      slide_platform_height { 2.5 }
      slide_wall_height { 1.8 }
      runout_value { 6.0 }
      slide_first_metre_height { 1.0 }
      slide_beyond_first_metre_height { 0.5 }
      slide_permanent_roof { true }
      slide_platform_height_comment { "Platform height comment" }
      slide_wall_height_comment { "Wall height comment" }
      runout_value_comment { "Runout comment" }
      slide_first_metre_height_comment { "First metre comment" }
      slide_beyond_first_metre_height_comment { "Beyond first metre comment" }
      slide_permanent_roof_comment { "Permanent roof comment" }
      
      # User height dimensions
      containing_wall_height { 1.2 }
      platform_height { 1.5 }
      tallest_user_height { 1.8 }
      users_at_1000mm { 8 }
      users_at_1200mm { 10 }
      users_at_1500mm { 12 }
      users_at_1800mm { 15 }
      play_area_length { 8.0 }
      play_area_width { 6.0 }
      negative_adjustment { 0.2 }
      permanent_roof { false }
      containing_wall_height_comment { "Containing wall comment" }
      platform_height_comment { "Platform height comment" }
      permanent_roof_comment { "Permanent roof comment" }
      play_area_length_comment { "Play area length comment" }
      play_area_width_comment { "Play area width comment" }
      negative_adjustment_comment { "Negative adjustment comment" }
      
      # Enclosed dimensions
      exit_number { 3 }
      exit_number_comment { "Exit number comment" }
      
      # Other dimensions
      rope_size { 18.0 }
      rope_size_comment { "Rope size comment" }
    end

    trait :with_inspection_copying_dimensions do
      # Different comprehensive values for testing inspection copying
      name { "Inspection Copy Test Unit" }
      manufacturer { "Copy Test Manufacturer" }
      model { "CTM-2024" }
      serial { "COPY-TEST-002" }
      description { "Unit for testing inspection copying" }
      owner { "Copy Test Owner Ltd" }
      manufacture_date { Date.new(2024, 2, 20) }
      has_slide { true }
      is_totally_enclosed { true }
      notes { "Copy test notes" }
      
      # Different dimensions for copy testing
      width { 15.0 }
      length { 12.0 }
      height { 5.0 }
      
      # Slide dimensions
      slide_platform_height { 3.0 }
      slide_wall_height { 2.2 }
      runout_value { 7.0 }
      slide_first_metre_height { 1.2 }
      slide_beyond_first_metre_height { 0.7 }
      slide_permanent_roof { false }
      slide_platform_height_comment { "Inspection platform comment" }
      slide_wall_height_comment { "Inspection wall comment" }
      runout_value_comment { "Inspection runout comment" }
      slide_first_metre_height_comment { "Inspection first metre comment" }
      slide_beyond_first_metre_height_comment { "Inspection beyond first metre comment" }
      slide_permanent_roof_comment { "Inspection roof comment" }
      
      # User height dimensions for inspection testing
      containing_wall_height { 1.5 }
      platform_height { 1.8 }
      tallest_user_height { 2.0 }
      users_at_1000mm { 12 }
      users_at_1200mm { 15 }
      users_at_1500mm { 18 }
      users_at_1800mm { 20 }
      play_area_length { 10.0 }
      play_area_width { 8.0 }
      negative_adjustment { 0.3 }
      permanent_roof { true }
      containing_wall_height_comment { "Inspection wall comment" }
      platform_height_comment { "Inspection platform comment" }
      permanent_roof_comment { "Inspection roof comment" }
      play_area_length_comment { "Inspection length comment" }
      play_area_width_comment { "Inspection width comment" }
      negative_adjustment_comment { "Inspection adjustment comment" }
    end

    trait :with_dimension_copying_test_data do
      width { 12.5 }
      length { 10.0 }
      height { 4.0 }
      num_low_anchors { 6 }
      num_high_anchors { 2 }
      rope_size { 15.0 }
      slide_platform_height { 2.5 }
      slide_wall_height { 1.8 }
      runout_value { 3.0 }
      containing_wall_height { 1.2 }
      platform_height { 2.0 }
      tallest_user_height { 1.8 }
      users_at_1000mm { 10 }
      users_at_1200mm { 15 }
      users_at_1500mm { 20 }
      users_at_1800mm { 25 }
      play_area_length { 9.5 }
      play_area_width { 9.5 }
    end

    trait :large do
      width { 10.0 }
      length { 8.0 }
      height { 5.0 }
    end

    trait :maximum_size_full_featured do
      has_slide { true }
      is_totally_enclosed { true }
      width { 15.5 }
      length { 20.3 }
      height { 8.7 }
      description { "Maximum size unit with all features for testing" }
    end

    trait :small do
      width { 2.0 }
      length { 2.0 }
      height { 1.5 }
    end

    trait :with_unicode_serial do
      sequence(:serial) { |n| "ÜNICØDÉ-😎-#{n}" }
    end
  end
end
