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

    # Base traits for dimension groups
    trait :with_slide_dimensions do
      has_slide { true }
      slide_platform_height { 1.8 }
      slide_wall_height { 1.5 }
      slide_first_metre_height { 1.0 }
      slide_beyond_first_metre_height { 0.8 }
      slide_permanent_roof { false }
      runout_value { 4.0 }
    end

    trait :with_slide_comments do
      slide_platform_height_comment { "Platform height suitable for age group" }
      slide_wall_height_comment { "Wall height meets safety requirements" }
      slide_first_metre_height_comment { "First metre height compliant" }
      slide_beyond_first_metre_height_comment { "Height beyond first metre appropriate" }
      slide_permanent_roof_comment { "No permanent roof structure" }
      runout_value_comment { "Adequate runout distance provided" }
    end

    trait :with_anchorage_dimensions do
      num_low_anchors { 6 }
      num_high_anchors { 2 }
      num_low_anchors_comment { "Low anchor comment" }
      num_high_anchors_comment { "High anchor comment" }
    end

    trait :with_structure_dimensions do
      stitch_length { 25.0 }
      evacuation_time { 45 }
      unit_pressure_value { 350.0 }
      blower_tube_length { 12.0 }
      step_size_value { 1.5 }
      fall_off_height_value { 2.0 }
      trough_depth_value { 0.8 }
      trough_width_value { 1.2 }
    end

    trait :with_user_height_dimensions do
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
    end

    trait :with_user_height_comments do
      containing_wall_height_comment { "Containing wall comment" }
      platform_height_comment { "Platform height comment" }
      permanent_roof_comment { "Permanent roof comment" }
      play_area_length_comment { "Play area length comment" }
      play_area_width_comment { "Play area width comment" }
      negative_adjustment_comment { "Negative adjustment comment" }
    end

    trait :with_basic_comments do
      width_comment { "Width comment" }
      length_comment { "Length comment" }
      height_comment { "Height comment" }
    end

    trait :with_enclosed_dimensions do
      is_totally_enclosed { true }
      exit_number { 2 }
      exit_number_comment { "Two emergency exits provided" }
    end

    trait :with_other_dimensions do
      rope_size { 18.0 }
      rope_size_comment { "Rope size comment" }
    end

    # Composite traits using the base traits
    trait :with_slide do
      with_slide_dimensions
      with_slide_comments
      description { "Test Unit with Slide" }
      width { 3.0 }
      length { 8.0 }
      height { 2.0 }
    end

    trait :totally_enclosed do
      with_enclosed_dimensions
      description { "Test Totally Enclosed Unit" }
    end

    trait :with_slide_and_enclosed do
      with_slide_dimensions
      with_enclosed_dimensions
      description { "Test Unit with Slide and Totally Enclosed" }
      width { 4.0 }
      length { 10.0 }
      height { 3.0 }
    end

    # Comprehensive dimensions using composition
    trait :with_comprehensive_dimensions do
      # Basic unit details
      name { "Complete Test Unit" }
      manufacturer { "Test Manufacturer" }
      model { "TM-2024" }
      serial { "TEST-SERIAL-001" }
      description { "A test unit with all fields populated" }
      owner { "Test Owner Ltd" }
      manufacture_date { Date.new(2024, 1, 15) }
      notes { "Test notes for unit" }

      # Basic dimensions with comments
      width { 12.5 }
      length { 10.0 }
      height { 4.5 }
      with_basic_comments

      # Include all dimension groups
      with_anchorage_dimensions
      with_structure_dimensions
      with_user_height_dimensions
      with_user_height_comments
      with_other_dimensions

      # Slide dimensions with custom values
      has_slide { true }
      slide_platform_height { 2.5 }
      slide_wall_height { 1.8 }
      runout_value { 6.0 }
      slide_first_metre_height { 1.0 }
      slide_beyond_first_metre_height { 0.5 }
      slide_permanent_roof { true }
      with_slide_comments

      # Enclosed dimensions with custom values
      is_totally_enclosed { true }
      exit_number { 3 }
      exit_number_comment { "Exit number comment" }
    end

    # Variation with different values but same structure
    trait :with_inspection_copying_dimensions do
      with_comprehensive_dimensions

      # Override specific values for testing
      name { "Inspection Copy Test Unit" }
      manufacturer { "Copy Test Manufacturer" }
      model { "CTM-2024" }
      serial { "COPY-TEST-002" }
      description { "Unit for testing inspection copying" }
      owner { "Copy Test Owner Ltd" }
      manufacture_date { Date.new(2024, 2, 20) }
      notes { "Copy test notes" }

      # Different basic dimensions
      width { 15.0 }
      length { 12.0 }
      height { 5.0 }

      # Override slide dimensions
      slide_platform_height { 3.0 }
      slide_wall_height { 2.2 }
      runout_value { 7.0 }
      slide_first_metre_height { 1.2 }
      slide_beyond_first_metre_height { 0.7 }
      slide_permanent_roof { false }

      # Override user height dimensions
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
    end

    # Simplified dimension copying test data
    trait :with_dimension_copying_test_data do
      width { 12.5 }
      length { 10.0 }
      height { 4.0 }
      with_anchorage_dimensions # Reuse the base trait
      rope_size { 15.0 }

      with_slide_dimensions # Reuse base slide dimensions
      slide_platform_height { 2.5 } # Override specific values
      runout_value { 3.0 }

      with_user_height_dimensions # Reuse base user height dimensions
      platform_height { 2.0 } # Override to match original
      users_at_1000mm { 10 }
      users_at_1200mm { 15 }
      users_at_1500mm { 20 }
      users_at_1800mm { 25 }
      play_area_length { 9.5 }
      play_area_width { 9.5 }
    end

    # Size traits
    trait :large do
      width { 10.0 }
      length { 8.0 }
      height { 5.0 }
    end

    trait :maximum_size_full_featured do
      with_slide_dimensions
      with_enclosed_dimensions
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

    # Simple trait that populates all fields
    trait :with_all_fields do
      with_comprehensive_dimensions
    end
  end
end
