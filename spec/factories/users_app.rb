# frozen_string_literal: true

# This extends the base user factory from the gem with app-specific traits
FactoryBot.modify do
  factory :user do
    association :inspection_company, factory: :inspector_company

    trait :without_company do
      inspection_company { nil }
    end
  end
end