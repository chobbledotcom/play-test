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
require "rails_helper"

RSpec.describe BadgeBatch, type: :model do
  describe "associations" do
    it "has many badges" do
      batch = create(:badge_batch)
      expect(batch).to respond_to(:badges)
    end

    it "destroys associated badges when batch is destroyed" do
      batch = create(:badge_batch)
      create(:badge, badge_batch: batch)
      create(:badge, badge_batch: batch)

      expect { batch.destroy }.to change(Badge, :count).by(-2)
    end
  end

  describe "count field" do
    it "stores the count of badges in the batch" do
      batch = create(:badge_batch, count: 5)
      expect(batch.count).to eq(5)
    end

    it "allows nil count" do
      batch = create(:badge_batch, count: nil)
      expect(batch).to be_valid
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
