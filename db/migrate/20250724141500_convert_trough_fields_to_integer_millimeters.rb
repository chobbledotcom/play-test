class ConvertTroughFieldsToIntegerMillimeters < ActiveRecord::Migration[8.0]
  def up
    # First, convert trough_adjacent_panel_width from meters to millimeters
    execute <<-SQL
      UPDATE structure_assessments#{" "}
      SET trough_adjacent_panel_width =#{" "}
        ROUND(trough_adjacent_panel_width * 1000)
      WHERE trough_adjacent_panel_width IS NOT NULL
    SQL

    # Then change both fields to integer type
    change_column :structure_assessments, :trough_depth, :integer
    change_column :structure_assessments,
      :trough_adjacent_panel_width, :integer
  end

  def down
    # Change fields back to decimal
    change_column :structure_assessments, :trough_depth,
      :decimal, precision: 8, scale: 2
    change_column :structure_assessments,
      :trough_adjacent_panel_width,
      :decimal, precision: 8, scale: 2

    # Convert trough_adjacent_panel_width back from millimeters to meters
    execute <<-SQL
      UPDATE structure_assessments#{" "}
      SET trough_adjacent_panel_width = trough_adjacent_panel_width / 1000.0
      WHERE trough_adjacent_panel_width IS NOT NULL
    SQL
  end
end
