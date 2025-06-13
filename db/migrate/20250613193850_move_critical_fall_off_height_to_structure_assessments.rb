class MoveCriticalFallOffHeightToStructureAssessments < ActiveRecord::Migration[8.0]
  def change
    # Rename the existing fields in structure_assessments to correct names
    rename_column :structure_assessments, :fall_off_height_value, :critical_fall_off_height
    rename_column :structure_assessments, :fall_off_height_pass, :critical_fall_off_height_pass
    rename_column :structure_assessments, :fall_off_height_comment, :critical_fall_off_height_comment
    
    # Remove duplicate fields from inspections table
    remove_column :inspections, :critical_fall_off_height, :decimal
    remove_column :inspections, :critical_fall_off_height_pass, :boolean
    remove_column :inspections, :critical_fall_off_height_comment, :string
  end
end
