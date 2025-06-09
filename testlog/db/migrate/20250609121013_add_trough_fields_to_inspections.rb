class AddTroughFieldsToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :trough_depth, :decimal
    add_column :inspections, :trough_adjacent_panel_width, :decimal
    add_column :inspections, :trough_pass, :boolean
  end
end
