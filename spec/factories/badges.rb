# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: badges
#
#  id             :string(8)        not null, primary key
#  note           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  badge_batch_id :integer          not null
#
# Indexes
#
#  index_badges_on_badge_batch_id  (badge_batch_id)
#  index_badges_on_id              (id) UNIQUE
#
# Foreign Keys
#
#  badge_batch_id  (badge_batch_id => badge_batches.id)
#
FactoryBot.define do
  factory :badge do
    association :badge_batch
    note { nil }
  end
end
