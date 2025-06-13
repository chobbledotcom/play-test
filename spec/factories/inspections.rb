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
    unique_report_number { nil } # User provides this manually
    complete_date { nil }
    is_seed { false }

    trait :passed do
      passed { true }
    end

    trait :failed do
      passed { false }
    end

    trait :complete do
      complete_date { Time.current }
    end

    trait :completed do
      complete_date { Time.current }
    end

    trait :draft do
      complete_date { nil }
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

    trait :with_complete_assessments do
      # Dimensions needed for calculations
      width { 5.5 }
      length { 6.0 }
      height { 4.5 }

      after(:create) do |inspection|
        # Update all assessments with complete data (assessments are already created by inspection callback)
        inspection.anchorage_assessment.update!(attributes_for(:anchorage_assessment, :complete).except(:inspection_id))
        inspection.enclosed_assessment.update!(attributes_for(:enclosed_assessment, :passed).except(:inspection_id))
        inspection.fan_assessment.update!(attributes_for(:fan_assessment, :complete).except(:inspection_id))
        inspection.materials_assessment.update!(attributes_for(:materials_assessment, :complete).except(:inspection_id))
        inspection.slide_assessment.update!(attributes_for(:slide_assessment, :complete).except(:inspection_id))
        inspection.structure_assessment.update!(attributes_for(:structure_assessment, :complete).except(:inspection_id))
        inspection.user_height_assessment.update!(attributes_for(:user_height_assessment, :complete).except(:inspection_id))
      end
    end

    trait :pdf_complete_test_data do
      complete_date { Time.current }
      inspection_location { "Happy Kids Play Centre" }
      passed { true }
      comments { "Test comments" }
      general_notes { "Test general notes" }
      recommendations { "Test recommendations" }
      unique_report_number { "RPII-20250609-#{SecureRandom.alphanumeric(6).upcase}" }

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

      # Risk assessment
      risk_assessment { "Low risk assessment notes" }

      # Use the complete assessments trait
      with_complete_assessments
    end

    trait :sql_injection_test do
      inspection_location { "Location'); UPDATE users SET admin=true; --" }
    end

    trait :max_length_comments do
      comments { "A" * 65535 }
    end

    trait :totally_enclosed do
      is_totally_enclosed { true }
    end

    trait :with_slide do
      has_slide { true }
    end
  end
end
