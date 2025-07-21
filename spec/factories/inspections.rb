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

      # Dimensions needed for a complete inspection
      width { 5.5 }
      length { 6.0 }
      height { 4.5 }

      after(:create) do |inspection|
        inspection.reload
        inspection.assessment_types.each do |assessment_name, assessment_class|
          assessment = assessment_class.create!(inspection: inspection)
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
        print_deprecation(
          "The :with_complete_assessments trait is deprecated. Inspections now auto-create all assessments. Use create(:inspection, :completed) instead.",
          trait_name: :with_complete_assessments
        )
      end

      # Dimensions needed for calculations
      width { 5.5 }
      length { 6.0 }
      height { 4.5 }

      after(:create) do |inspection|
        # Update all assessments with complete data (assessments are already created by inspection callback)
        Inspection::ASSESSMENT_TYPES.each_key do |assessment_type|
          assessment = inspection.send(assessment_type)
          assessment_factory = assessment_type.to_s.sub(/_assessment$/, "").to_sym
          complete_attrs = attributes_for(:"#{assessment_factory}_assessment", :complete)
          assessment.update!(complete_attrs.except(:inspection_id))
        end
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
        print_deprecation(
          "Inspections are totally enclosed by default. Remove this trait, or use :not_totally_enclosed for the opposite.",
          trait_name: :totally_enclosed
        )
      end
      is_totally_enclosed { true }
    end

    trait :with_slide do
      after(:build) do |_inspection|
        print_deprecation(
          "Inspections have slides by default. Remove this trait, or use :without_slide for the opposite.",
          trait_name: :with_slide
        )
      end
      has_slide { true }
    end
  end
end
