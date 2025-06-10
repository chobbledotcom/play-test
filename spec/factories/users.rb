FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:rpii_inspector_number) { |n| "RPII#{n.to_s.rjust(3, "0")}" }
    time_display { "date" }
    active_until { nil }
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

    trait :without_company do
      inspection_company { nil }
    end
  end
end
