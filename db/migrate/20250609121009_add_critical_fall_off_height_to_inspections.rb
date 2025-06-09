class AddCriticalFallOffHeightToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :critical_fall_off_height, :decimal
    add_column :inspections, :critical_fall_off_height_pass, :boolean
  end
end
