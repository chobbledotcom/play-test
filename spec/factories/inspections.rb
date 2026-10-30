# typed: false

# == Schema Information
#
# Table name: inspections
#
#  id                   :string(12)       not null, primary key
#  complete_date        :datetime
#  has_slide            :boolean
#  height               :decimal(8, 2)
#  height_comment       :string(1000)
#  indoor_only          :boolean
#  inspection_date      :datetime
#  inspection_type      :string           default("bouncy_castle"), not null
#  is_seed              :boolean          default(FALSE), not null
#  is_totally_enclosed  :boolean
#  length               :decimal(8, 2)
#  length_comment       :string(1000)
#  passed               :boolean
#  pdf_last_accessed_at :datetime
#  risk_assessment      :text
#  width                :decimal(8, 2)
#  width_comment        :string(1000)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  inspector_company_id :string
#  unit_id              :string
#  user_id              :string(12)       not null
#
# Indexes
#
#  index_inspections_on_inspection_type       (inspection_type)
#  index_inspections_on_inspector_company_id  (inspector_company_id)
#  index_inspections_on_is_seed               (is_seed)
#  index_inspections_on_unit_id               (unit_id)
#  index_inspections_on_user_id               (user_id)
#
# Foreign Keys
#
#  inspector_company_id  (inspector_company_id => inspector_companies.id)
#  unit_id               (unit_id => units.id)
#  user_id               (user_id => users.id)
#
FactoryBot.define do
  factory :inspection do
    association :user
    association :unit, factory: :unit

    # Always use the user's inspection company
    inspector_company { user.inspection_company }

    passed { true }
    has_slide { unit.nil? || unit.configuration_fields.include?(:has_slide) }
    is_totally_enclosed {
      unit.nil? || unit.configuration_fields.include?(:is_totally_enclosed)
    }
    indoor_only { false }
    inspection_date { Date.current }
    complete_date { nil }
    is_seed { false }
    operator { "Test Operator" }
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
      inspection_location { "Test installation site" if unit&.bouncing_pillow? }
      indoor_only { false }

      after(:create) do |inspection|
        inspection.reload
        inspection.applicable_assessments.each_key do |assessment_name|
          assessment = inspection.send(assessment_name)
          complete_attrs = FactoryBot.attributes_for(assessment_name, :complete)
          assessment.update!(complete_attrs)
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
        # Update all assessments (built lazily by the inspection model)
        Inspection::ASSESSMENT_TYPES.each_key do |assessment_type|
          assessment = inspection.send(assessment_type)
          assessment_factory = assessment_type.to_s.sub(/_assessment$/, "").to_sym
          complete_attrs = attributes_for(:"#{assessment_factory}_assessment", :complete)
          assessment.update!(complete_attrs.except(:inspection_id))
        end
      end
    end

    trait :sql_injection_test do
      risk_assessment { "Risk'); UPDATE users SET admin=true; --" }
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

    trait :indoor_only do
      indoor_only { true }
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
