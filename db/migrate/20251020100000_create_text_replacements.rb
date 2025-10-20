# typed: true
# frozen_string_literal: true

class CreateTextReplacements < ActiveRecord::Migration[8.0]
  def change
    create_table :text_replacements do |t|
      t.string :i18n_key, null: false
      t.text :value, null: false

      t.timestamps
    end

    add_index :text_replacements, :i18n_key, unique: true
  end
end
