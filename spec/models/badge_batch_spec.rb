# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe BadgeBatch, type: :model do
  describe "associations" do
    it "has many badges" do
      batch = create(:badge_batch)
      expect(batch).to respond_to(:badges)
    end

    it "destroys associated badges when batch is destroyed" do
      batch = create(:badge_batch)
      badge1 = create(:badge, badge_batch: batch)
      badge2 = create(:badge, badge_batch: batch)

      expect { batch.destroy }.to change(Badge, :count).by(-2)
    end
  end

  describe "#badge_count" do
    it "returns correct count of badges" do
      batch = create(:badge_batch)
      create_list(:badge, 3, badge_batch: batch)

      expect(batch.badge_count).to eq(3)
    end

    it "returns 0 when batch has no badges" do
      batch = create(:badge_batch)
      expect(batch.badge_count).to eq(0)
    end
  end

  describe "note field" do
    it "allows nil note" do
      batch = create(:badge_batch, note: nil)
      expect(batch).to be_valid
    end

    it "allows custom note" do
      batch = create(:badge_batch, note: "Test batch note")
      expect(batch.note).to eq("Test batch note")
    end
  end
end
