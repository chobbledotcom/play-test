FactoryBot.define do
  factory :inspection do
    association :user
    association :unit, factory: :unit

    # Always use the user's inspection company
    inspector_company { user.inspection_company }

    inspection_location { "Test Location" }
    passed { true }
    inspection_date { Date.current }
    comments { "Test inspection comments" }
    sequence(:unique_report_number) { |n| "RPII-#{Date.current.strftime("%Y%m%d")}-#{n.to_s.rjust(4, "0")}" }
    status { "draft" }

    trait :passed do
      passed { true }
    end

    trait :failed do
      passed { false }
    end

    trait :complete do
      status { "complete" }
    end

    trait :completed do
      status { "complete" }
    end

    trait :draft do
      status { "draft" }
    end

    trait :overdue do
      inspection_date { Date.current - 1.year - 1.month }
    end

    trait :future_inspection do
      inspection_date { Date.current + 1.week }
    end

    trait :with_unicode_data do
      inspection_location { "Meeting Room 🏢 3F" }
      comments { "❗️Tested with special 🔌 adapter. Result: ✅" }
      association :unit, factory: [:unit, :with_unicode_serial]
    end

    trait :with_comprehensive_dimensions do
      unit { nil } # No unit initially for testing inspection -> unit copying
      inspection_location { "Test Location" }

      # All comprehensive attributes for testing copying
      width { 15.0 }
      length { 12.0 }
      height { 5.0 }
      width_comment { "Inspection width comment" }
      length_comment { "Inspection length comment" }
      height_comment { "Inspection height comment" }
      has_slide { true }
      is_totally_enclosed { true }

      num_low_anchors { 8 }
      num_high_anchors { 4 }
      num_low_anchors_comment { "Inspection low anchor comment" }
      num_high_anchors_comment { "Inspection high anchor comment" }

      stitch_length { 30.0 }
      evacuation_time { 50 }
      unit_pressure_value { 400.0 }
      blower_tube_length { 15.0 }
      step_size_value { 2.0 }
      fall_off_height_value { 2.5 }
      trough_depth_value { 1.0 }
      trough_width_value { 1.5 }

      slide_platform_height { 3.0 }
      slide_wall_height { 2.2 }
      runout_value { 8.0 }
      slide_first_metre_height { 1.2 }
      slide_beyond_first_metre_height { 0.8 }
      slide_permanent_roof { false }
      slide_platform_height_comment { "Inspection platform comment" }
      slide_wall_height_comment { "Inspection wall comment" }
      runout_value_comment { "Inspection runout comment" }
      slide_first_metre_height_comment { "Inspection first metre comment" }
      slide_beyond_first_metre_height_comment { "Inspection beyond first metre comment" }
      slide_permanent_roof_comment { "Inspection roof comment" }

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
      containing_wall_height_comment { "Inspection containing wall comment" }
      platform_height_comment { "Inspection platform height comment" }
      permanent_roof_comment { "Inspection permanent roof comment" }
      play_area_length_comment { "Inspection play area length comment" }
      play_area_width_comment { "Inspection play area width comment" }
      negative_adjustment_comment { "Inspection negative adjustment comment" }

      exit_number { 5 }
      exit_number_comment { "Inspection exit number comment" }

      rope_size { 22.0 }
      rope_size_comment { "Inspection rope size comment" }
    end

    trait :pdf_complete_test_data do
      status { "complete" }
      inspection_location { "Happy Kids Play Centre" }
      passed { true }
      comments { "Test comments" }
      general_notes { "Test general notes" }
      recommendations { "Test recommendations" }
      unique_report_number { "RPII-20250609-ABC123" }

      # Dimensions
      width { 5.5 }
      length { 6.0 }
      height { 4.5 }

      # Step and ramp measurements
      step_ramp_size { 0.3 }
      step_ramp_size_pass { true }
      critical_fall_off_height { 1.2 }
      critical_fall_off_height_pass { true }

      # Unit pressure
      unit_pressure { 2.5 }
      unit_pressure_pass { true }

      # Trough measurements
      trough_depth { 0.1 }
      trough_adjacent_panel_width { 0.8 }
      trough_pass { true }

      # Safety checks - all passing
      entrapment_pass { true }
      markings_id_pass { true }
      grounding_pass { true }
      clamber_netting_pass { true }
      retention_netting_pass { true }
      zips_pass { true }
      windows_pass { true }
      artwork_pass { true }
      exit_sign_visible_pass { true }

      # Risk assessment
      risk_assessment { "Low risk assessment notes" }
    end

    trait :sql_injection_test do
      inspection_location { "Location'); UPDATE users SET admin=true; --" }
    end

    trait :max_length_comments do
      comments { "A" * 65535 }
    end
  end
end
