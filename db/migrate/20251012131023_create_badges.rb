# typed: true
# frozen_string_literal: true

class CreateBadges < ActiveRecord::Migration[8.0]
  def change
    create_table :badges, id: false do |t|
      t.string :id, limit: 8, null: false, primary_key: true
      t.references :badge_batch, null: false, foreign_key: true
      t.text :note

      t.timestamps
    end

    add_index :badges, :id, unique: true
  end
end
