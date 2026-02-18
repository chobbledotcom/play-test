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
    manufacture_date { 1.year.ago }
    is_seed { false }

    transient do
      badge_batch { nil }
      explicit_id { :not_set }
    end

    # Automatically create badge when UNIT_BADGES=true
    # Only if id was not explicitly set (even to nil)
    after(:build) do |unit, evaluator|
      badges_enabled = Rails.configuration.units.badges_enabled
      id_not_explicitly_set = evaluator.explicit_id == :not_set

      should_create_badge = badges_enabled &&
        id_not_explicitly_set &&
        unit.id.blank?

      if should_create_badge
        batch = evaluator.badge_batch ||
          FactoryBot.create(:badge_batch, count: 1)
        badge = FactoryBot.create(:badge, badge_batch: batch)
        unit.id = badge.id
      elsif evaluator.explicit_id != :not_set
        unit.id = evaluator.explicit_id
      end
    end

    # with_badge trait: for explicitly creating a badge when badges disabled
    # When UNIT_BADGES=true, badges are created automatically by default
    trait :with_badge do
      after(:build) do |unit, evaluator|
        # Only create badge if badges are disabled globally
        # (when enabled, the default callback already handles it)
        unless Rails.configuration.units.badges_enabled
          batch = evaluator.badge_batch ||
            FactoryBot.create(:badge_batch, count: 1)
          badge = FactoryBot.create(:badge, badge_batch: batch)
          unit.id = badge.id
        end
      end
    end

    # Variation with different values
    trait :with_different_values do
      name { "Different Test Unit" }
      manufacturer { "Different Manufacturer" }
      serial { "DIFF-TEST-001" }
      description { "A different test unit" }
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
      manufacture_date { Date.new(2024, 1, 15) }
    end
  end
end
