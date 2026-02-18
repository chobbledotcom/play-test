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
require "rails_helper"

RSpec.describe Badge, type: :model do
  describe "associations" do
    it "belongs to badge_batch" do
      badge = create(:badge)
      expect(badge.badge_batch).to be_a(BadgeBatch)
    end
  end

  describe "ID generation" do
    it "generates a custom string ID on creation" do
      batch = create(:badge_batch)
      badge = Badge.create!(badge_batch: batch)

      expect(badge.id).to be_present
      expect(badge.id).to be_a(String)
      expect(badge.id.length).to eq(8)
    end

    it "generates unique IDs" do
      batch = create(:badge_batch)
      badge1 = Badge.create!(badge_batch: batch)
      badge2 = Badge.create!(badge_batch: batch)

      expect(badge1.id).not_to eq(badge2.id)
    end

    it "excludes ambiguous characters from IDs" do
      batch = create(:badge_batch)
      100.times do
        badge = Badge.create!(badge_batch: batch)
        ambiguous_chars = %w[0 O 1 I L]
        ambiguous_chars.each do |char|
          expect(badge.id).not_to include(char)
        end
      end
    end
  end

  describe "note field" do
    it "allows nil note" do
      badge = create(:badge, note: nil)
      expect(badge).to be_valid
    end

    it "allows custom note" do
      badge = create(:badge, note: "Test note")
      expect(badge.note).to eq("Test note")
    end
  end
end
