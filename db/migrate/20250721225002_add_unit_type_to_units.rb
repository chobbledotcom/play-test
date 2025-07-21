class AddUnitTypeToUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :units, :unit_type, :string,
      null: false, default: "BOUNCY_CASTLE"
    add_index :units, :unit_type
  end
end
