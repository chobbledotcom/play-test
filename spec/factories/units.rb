# typed: false

# == Schema Information
#
# Table name: units
#
#  id               :string(12)       not null, primary key
#  description      :string
#  is_seed          :boolean          default(FALSE), not null
#  manufacture_date :date
#  manufacturer     :string
#  name             :string
#  operator         :string
#  serial           :string
#  unit_type        :string           default("bouncy_castle"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :string(12)       not null
#
# Indexes
#
#  index_units_on_is_seed                  (is_seed)
#  index_units_on_manufacturer_and_serial  (manufacturer,serial) UNIQUE
#  index_units_on_serial_and_user_id       (serial,user_id) UNIQUE
#  index_units_on_unit_type                (unit_type)
#  index_units_on_user_id                  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
FactoryBot.define do
  factory :unit do
    association :user
    sequence(:name) { |n| "Test Unit #{n}" }
    serial { SecureRandom.hex(10) }
    description { "Test Bouncy Castle" }
    manufacturer { "Test Manufacturer" }
    operator { "Test Operator" }
    manufacture_date { 1.year.ago }
    is_seed { false }

    # Variation with different values
    trait :with_different_values do
      name { "Different Test Unit" }
      manufacturer { "Different Manufacturer" }
      serial { "DIFF-TEST-001" }
      description { "A different test unit" }
      operator { "Different Operator Ltd" }
      manufacture_date { Date.new(2024, 2, 20) }
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
      serial { "PRM-SERIAL-001" }
      description { "Premium bouncy castle with all features" }
      operator { "Test Events Company" }
      manufacture_date { Date.new(2024, 1, 15) }
    end
  end
end
