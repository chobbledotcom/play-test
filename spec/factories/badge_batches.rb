# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: badge_batches
#
#  id         :integer          not null, primary key
#  count      :integer
#  note       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :badge_batch do
    note { "Test batch" }
    count { nil }

    trait :with_badges do
      count { 5 }

      after(:create) do |batch|
        create_list(:badge, 5, badge_batch: batch)
      end
    end
  end
end
