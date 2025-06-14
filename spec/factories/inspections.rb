FactoryBot.define do
  factory :inspection do
    association :user
    association :unit, factory: :unit

    # Always use the user's inspection company
    inspector_company { user.inspection_company }

    inspection_location { "Test Location" }
    passed { true }
    inspection_date { Date.current }
    unique_report_number { nil } # User provides this manually
    complete_date { nil }
    is_seed { false }
    risk_assessment {
      "Standard risk assessment completed. Unit inspected in accordance with EN 14960:2019. " \
      "All safety features present and functional. No significant hazards identified. " \
      "Unit suitable for continued operation with appropriate supervision."
    }

    trait :passed do
      passed { true }
    end

    trait :failed do
      passed { false }
      risk_assessment {
        "Risk assessment identifies critical safety issues. Multiple failures detected including " \
        "compromised structural integrity and inadequate anchoring. Unit poses unacceptable risk " \
        "to users and must be withdrawn from service immediately pending repairs."
      }
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
      risk_assessment { "❗️Tested with special 🔌 adapter. Result: ✅" }
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
      unique_report_number { "RPII-20250609-#{SecureRandom.alphanumeric(6).upcase}" }

      # Risk assessment
      risk_assessment { "Low risk assessment notes" }

      # Use the complete assessments trait
      with_complete_assessments

      after(:create) do |inspection|
        inspection.structure_assessment.update!(
          step_ramp_size: 0.3,
          step_ramp_size_pass: true,
          trough_depth: 0.1,
          trough_adjacent_panel_width: 0.8,
          unit_pressure: 2.5,
          unit_pressure_pass: true,
          critical_fall_off_height: 1.2,
          critical_fall_off_height_pass: true
        )

        # Add some test comments
        inspection.anchorage_assessment.update!(
          num_low_anchors_comment: "Additional low anchors recommended for high wind area",
          num_high_anchors_comment: "High anchor count adequate",
          anchor_type_comment: "D-ring anchors in good condition"
        )

        inspection.structure_assessment.update!(
          seam_integrity_comment: "All seams checked and secure",
          unit_stable_comment: "Unit remained stable during 60 second test"
        )
      end
    end

    trait :sql_injection_test do
      inspection_location { "Location'); UPDATE users SET admin=true; --" }
    end

    trait :with_unicode_data do
      risk_assessment { "❗️Tested with special 🔌 adapter. Result: ✅" }
      association :unit, factory: [:unit, :with_unicode_serial]
    end

    trait :max_length_risk_assessment do
      risk_assessment { "A" * 65535 }
    end

    trait :totally_enclosed do
      is_totally_enclosed { true }
    end

    trait :with_slide do
      has_slide { true }
    end
  end
end
