FactoryBot.define do
  factory :user, class: "ChobbleApp::User" do
    sequence(:email) { |n| "user#{n}_#{SecureRandom.hex(4)}@example.com" }
    sequence(:name) { |n| "Test User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:rpii_inspector_number) { |n| "RPII#{n.to_s.rjust(3, "0")}_#{SecureRandom.hex(2)}" }
    # Default factory creates active users for tests - real signups will be inactive
    active_until { Date.current + 1.year }

    trait :admin do
      sequence(:email) { |n| "admin#{n}_#{SecureRandom.hex(4)}@example.com" }
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

    trait :with_full_details do
      name { "John Doe" }
      phone { "1234567890" }
      address { "123 Test Street, Test City" }
      country { "UK" }
      postal_code { "12345" }
    end

    trait :without_rpii do
      rpii_inspector_number { nil }
    end
  end
end
