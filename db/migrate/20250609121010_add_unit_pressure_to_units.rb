class AddUnitPressureToUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :units, :unit_pressure, :decimal
  end
end
