# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :badge do
    association :badge_batch
    note { nil }
  end
end
