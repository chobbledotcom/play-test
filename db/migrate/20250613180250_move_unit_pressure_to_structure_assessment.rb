class MoveUnitPressureToStructureAssessment < ActiveRecord::Migration[8.0]
  def up
    # Migrate data from inspections to structure_assessments
    # unit_pressure_value already exists in structure_assessments
    execute <<-SQL
      UPDATE structure_assessments 
      SET unit_pressure_value = (
        SELECT unit_pressure 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id
      ),
      unit_pressure_pass = (
        SELECT unit_pressure_pass 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id 
        AND (inspections.unit_pressure IS NOT NULL OR inspections.unit_pressure_pass IS NOT NULL)
      )
    SQL
    
    # Remove fields from inspections
    remove_column :inspections, :unit_pressure
    remove_column :inspections, :unit_pressure_pass
  end
  
  def down
    # Add fields back to inspections
    add_column :inspections, :unit_pressure, :decimal, precision: 8, scale: 2
    add_column :inspections, :unit_pressure_pass, :boolean
    
    # Migrate data back from structure_assessments to inspections
    execute <<-SQL
      UPDATE inspections 
      SET unit_pressure = (
        SELECT unit_pressure_value 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id
      ),
      unit_pressure_pass = (
        SELECT unit_pressure_pass 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id 
        AND (structure_assessments.unit_pressure_value IS NOT NULL OR structure_assessments.unit_pressure_pass IS NOT NULL)
      )
    SQL
  end
end
