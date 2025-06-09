class AddUnitPressureToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :unit_pressure, :decimal
    add_column :inspections, :unit_pressure_pass, :boolean
  end
end
