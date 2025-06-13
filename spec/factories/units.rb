FactoryBot.define do
  factory :unit do
    association :user
    sequence(:name) { |n| "Test Unit #{n}" }
    sequence(:serial) { |n| "TEST#{n.to_s.rjust(3, "0")}" }
    description { "Test Bouncy Castle" }
    manufacturer { "Test Manufacturer" }
    owner { "Test Owner" }
    model { "Test Model" }
    manufacture_date { 1.year.ago }
    notes { "Test notes" }
    is_seed { false }

    # Variation with different values
    trait :with_different_values do
      name { "Different Test Unit" }
      manufacturer { "Different Manufacturer" }
      model { "DM-2024" }
      serial { "DIFF-TEST-001" }
      description { "A different test unit" }
      owner { "Different Owner Ltd" }
      manufacture_date { Date.new(2024, 2, 20) }
      notes { "Different test notes" }
    end

    # Size-related descriptions (no actual dimensions anymore)
    trait :large_description do
      description { "Large bouncy castle with multiple play areas" }
    end

    trait :small_description do
      description { "Small compact bouncy castle" }
    end

    trait :totally_enclosed_description do
      description { "Totally enclosed inflatable play structure" }
    end

    trait :with_unicode_serial do
      sequence(:serial) { |n| "ÜNICØDÉ-😎-#{n}" }
    end

    # Simple trait for comprehensive test data
    trait :with_all_fields do
      name { "Complete Test Unit" }
      manufacturer { "Premium Inflatables Ltd" }
      model { "PRM-2024-XL" }
      serial { "PRM-SERIAL-001" }
      description { "Premium bouncy castle with all features" }
      owner { "Test Events Company" }
      manufacture_date { Date.new(2024, 1, 15) }
      notes { "Well-maintained unit, regular inspections completed" }
    end
  end
end
