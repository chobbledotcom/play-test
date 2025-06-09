class AddTroughFieldsToUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :units, :trough_depth, :decimal
    add_column :units, :trough_adjacent_panel_width, :decimal
  end
end
