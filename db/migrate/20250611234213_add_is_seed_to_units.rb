class AddIsSeedToUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :units, :is_seed, :boolean, default: false, null: false
    add_index :units, :is_seed
  end
end
