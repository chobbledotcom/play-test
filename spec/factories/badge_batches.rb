# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :badge_batch do
    note { "Test batch" }

    trait :with_badges do
      after(:create) do |batch|
        create_list(:badge, 5, badge_batch: batch)
      end
    end
  end
end
