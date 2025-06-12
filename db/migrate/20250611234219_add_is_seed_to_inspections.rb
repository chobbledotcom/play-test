class AddIsSeedToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :is_seed, :boolean, default: false, null: false
    add_index :inspections, :is_seed
  end
end
