# frozen_string_literal: true

class CreateCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :credentials do |t|
      t.references :user, type: :string, limit: 12, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :nickname, null: false
      t.integer :sign_count, null: false, default: 0

      t.timestamps
    end
    add_index :credentials, :external_id, unique: true
  end
end
