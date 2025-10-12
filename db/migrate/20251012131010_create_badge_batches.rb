# typed: true
# frozen_string_literal: true

class CreateBadgeBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :badge_batches do |t|
      t.text :note

      t.timestamps
    end
  end
end
