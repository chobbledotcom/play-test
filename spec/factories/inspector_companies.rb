# typed: false

# == Schema Information
#
# Table name: inspector_companies
#
#  id          :string(8)        not null, primary key
#  active      :boolean          default(TRUE)
#  address     :text             not null
#  city        :string
#  country     :string           default("UK")
#  email       :string
#  name        :string           not null
#  notes       :text
#  phone       :string           not null
#  postal_code :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_inspector_companies_on_active  (active)
#
require "test_data_helpers"

FactoryBot.define do
  factory :inspector_company do
    sequence(:name) { |n| "Test Company #{n}" }
    phone { "1234567890" }
    address { "123 Test Street" }
    city { "Test City" }
    postal_code { "12345" }
    email { "company@example.com" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_email do
      sequence(:email) { |n| "company#{n}@example.com" }
    end

    trait :international_phone do
      phone { "+44 20 1234 5678" }
    end

    trait :formatted_phone do
      phone { "(123) 456-7890" }
    end

    trait :archived do
      active { false }
    end

    trait :british do
      phone { TestDataHelpers.british_phone_number }
      address { TestDataHelpers.british_address }
      city { TestDataHelpers.british_city }
      postal_code { TestDataHelpers.british_postcode }
      country { "UK" }
    end
  end
end
