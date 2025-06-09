class AddCriticalFallOffHeightToUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :units, :critical_fall_off_height, :decimal
  end
end
