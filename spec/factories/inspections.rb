FactoryBot.define do
  factory :inspection do
    association :user
    association :unit, factory: :unit

    # Always use the user's inspection company
    inspector_company { user.inspection_company }

    inspection_location { "Test Location" }
    passed { true }
    has_slide { true }
    is_totally_enclosed { true }
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

    trait :completed do
      complete_date { Time.current }

      after(:create) do |inspection|
        inspection.reload
        Inspection::ASSESSMENT_TYPES.each do |assessment_name, _assessment_class|
          assessment = inspection.send(assessment_name)
          assessment.update!(attributes_for(assessment_name, :complete))
        end
      end
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
      after(:build) do |_inspection|
        warn "[DEPRECATION] The :with_complete_assessments trait is deprecated as inspections are totally enclosed by default. Remove this trait from your test and use create(:inspection) instead."
      end

      # Dimensions needed for calculations
      width { 5.5 }
      length { 6.0 }
      height { 4.5 }

      after(:create) do |inspection|
        # Update all assessments with complete data (assessments are already created by inspection callback)
        inspection.anchorage_assessment.update!(attributes_for(:anchorage_assessment, :complete).except(:inspection_id))
        inspection.enclosed_assessment.update!(attributes_for(:enclosed_assessment, :complete).except(:inspection_id))
        inspection.fan_assessment.update!(attributes_for(:fan_assessment, :complete).except(:inspection_id))
        inspection.materials_assessment.update!(attributes_for(:materials_assessment, :complete).except(:inspection_id))
        inspection.slide_assessment.update!(attributes_for(:slide_assessment, :complete).except(:inspection_id))
        inspection.structure_assessment.update!(attributes_for(:structure_assessment, :complete).except(:inspection_id))
        inspection.user_height_assessment.update!(attributes_for(:user_height_assessment, :complete).except(:inspection_id))
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

    trait :not_totally_enclosed do
      is_totally_enclosed { false }
    end

    trait :without_slide do
      has_slide { false }
    end

    trait :totally_enclosed do
      after(:build) do |_inspection|
        warn "[DEPRECATION] The :totally_enclosed trait is deprecated as inspections are totally enclosed by default. Remove this trait from your test, or use :not_totally_enclosed if you want the opposite."
      end
      is_totally_enclosed { true }
    end

    trait :with_slide do
      after(:build) do |_inspection|
        warn "[DEPRECATION] The :with_slide trait is deprecated as inspections have slides by default. Remove this trait from your test, or use :without_slide if you want the opposite."
      end
      has_slide { true }
    end
  end
end
