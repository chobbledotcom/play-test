FactoryBot.define do
  factory :inspector_company do
    association :user
    sequence(:name) { |n| "Test Company #{n}" }
    sequence(:rpii_registration_number) { |n| "RPII#{n.to_s.rjust(3, "0")}" }
    phone { "1234567890" }
    address { "123 Test Street" }
    city { "Test City" }
    state { "Test State" }
    postal_code { "12345" }
    email { "company@example.com" }
    rpii_verified { false }
    active { true }

    trait :verified do
      rpii_verified { true }
    end

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
  end
end
