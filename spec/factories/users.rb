FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "Test User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:rpii_inspector_number) { |n| "RPII#{n.to_s.rjust(3, "0")}" }
    time_display { "date" }
    # Default factory creates active users for tests - real signups will be inactive
    active_until { Date.current + 1.year }
    association :inspection_company, factory: :inspector_company

    trait :admin do
      sequence(:email) { |n| "admin#{n}@example.com" }
    end

    trait :active_user do
      active_until { Date.current + 1.year }
    end

    trait :inactive_user do
      active_until { Date.current - 1.day }
    end

    trait :newly_signed_up do
      # This simulates the real signup behavior
      active_until { Date.current - 1.day }
    end

    trait :without_company do
      inspection_company { nil }
      name { "John Doe" }
      phone { "1234567890" }
      address { "123 Test Street, Test City" }
      country { "UK" }
      postal_code { "12345" }
    end
  end
end
