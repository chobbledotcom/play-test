class MoveTroughFieldsToStructureAssessment < ActiveRecord::Migration[8.0]
  def up
    # Add new fields to structure_assessments
    add_column :structure_assessments, :trough_depth_value_pass, :boolean
    add_column :structure_assessments, :trough_adjacent_panel_width, :decimal, precision: 8, scale: 2
    add_column :structure_assessments, :trough_adjacent_panel_width_pass, :boolean
    add_column :structure_assessments, :trough_adjacent_panel_width_comment, :text

    # Migrate data from inspections to structure_assessments
    execute <<-SQL
      UPDATE structure_assessments 
      SET trough_depth_value = (
        SELECT trough_depth 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id 
        AND inspections.trough_depth IS NOT NULL
      )
    SQL

    execute <<-SQL
      UPDATE structure_assessments 
      SET trough_adjacent_panel_width = (
        SELECT trough_adjacent_panel_width 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id 
        AND inspections.trough_adjacent_panel_width IS NOT NULL
      )
    SQL

    # Remove fields from inspections
    remove_column :inspections, :trough_depth
    remove_column :inspections, :trough_adjacent_panel_width
  end

  def down
    # Add fields back to inspections
    add_column :inspections, :trough_depth, :decimal, precision: 8, scale: 2
    add_column :inspections, :trough_adjacent_panel_width, :decimal, precision: 8, scale: 2

    # Migrate data back from structure_assessments to inspections
    execute <<-SQL
      UPDATE inspections 
      SET trough_depth = (
        SELECT trough_depth_value 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id 
        AND structure_assessments.trough_depth_value IS NOT NULL
      )
    SQL

    execute <<-SQL
      UPDATE inspections 
      SET trough_adjacent_panel_width = (
        SELECT trough_adjacent_panel_width 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id 
        AND structure_assessments.trough_adjacent_panel_width IS NOT NULL
      )
    SQL

    # Remove fields from structure_assessments
    remove_column :structure_assessments, :trough_depth_value_pass
    remove_column :structure_assessments, :trough_adjacent_panel_width
    remove_column :structure_assessments, :trough_adjacent_panel_width_pass
    remove_column :structure_assessments, :trough_adjacent_panel_width_comment
  end
end
