# typed: false

# == Schema Information
#
# Table name: users
#
#  id                    :string(8)        not null, primary key
#  active_until          :date
#  address               :text
#  country               :string
#  email                 :string
#  last_active_at        :datetime
#  name                  :string
#  password_digest       :string
#  phone                 :string
#  postal_code           :string
#  rpii_inspector_number :string
#  rpii_verified_date    :datetime
#  theme                 :string           default("light")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inspection_company_id :string
#  webauthn_id           :string
#
# Indexes
#
#  index_users_on_email                  (email) UNIQUE
#  index_users_on_inspection_company_id  (inspection_company_id)
#  index_users_on_rpii_inspector_number  (rpii_inspector_number) UNIQUE WHERE rpii_inspector_number IS NOT NULL
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}_#{SecureRandom.hex(4)}@example.com" }
    sequence(:name) { |n| "Test User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:rpii_inspector_number) { |n| "RPII#{n.to_s.rjust(3, "0")}_#{SecureRandom.hex(2)}" }
    # Default factory creates active users for tests - real signups will be inactive
    active_until { Date.current + 1.year }
    association :inspection_company, factory: :inspector_company

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

    trait :without_company do
      inspection_company { nil }
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
