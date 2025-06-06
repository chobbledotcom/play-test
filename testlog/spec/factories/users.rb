FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    inspection_limit { 10 }
    time_display { "date" }

    trait :admin do
      sequence(:email) { |n| "admin#{n}@example.com" }
    end

    trait :unlimited_inspections do
      inspection_limit { -1 }
    end

    trait :limited_inspections do
      inspection_limit { 2 }
    end
  end
end
