class MoveStepRampSizeToStructureAssessment < ActiveRecord::Migration[8.0]
  def up
    # Add new fields to structure_assessments
    add_column :structure_assessments, :step_ramp_size, :decimal, precision: 8, scale: 2
    add_column :structure_assessments, :step_ramp_size_pass, :boolean
    add_column :structure_assessments, :step_ramp_size_comment, :text

    # Migrate data from inspections to structure_assessments
    execute <<-SQL
      UPDATE structure_assessments 
      SET step_ramp_size = (
        SELECT step_ramp_size 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id
      ),
      step_ramp_size_pass = (
        SELECT step_ramp_size_pass 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id
      ),
      step_ramp_size_comment = (
        SELECT step_ramp_size_comment 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM inspections 
        WHERE inspections.id = structure_assessments.inspection_id 
        AND (inspections.step_ramp_size IS NOT NULL 
          OR inspections.step_ramp_size_pass IS NOT NULL
          OR inspections.step_ramp_size_comment IS NOT NULL)
      )
    SQL

    # Remove fields from inspections
    remove_column :inspections, :step_ramp_size
    remove_column :inspections, :step_ramp_size_pass
    remove_column :inspections, :step_ramp_size_comment
  end

  def down
    # Add fields back to inspections
    add_column :inspections, :step_ramp_size, :decimal, precision: 8, scale: 2
    add_column :inspections, :step_ramp_size_pass, :boolean
    add_column :inspections, :step_ramp_size_comment, :string, limit: 1000

    # Migrate data back from structure_assessments to inspections
    execute <<-SQL
      UPDATE inspections 
      SET step_ramp_size = (
        SELECT step_ramp_size 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id
      ),
      step_ramp_size_pass = (
        SELECT step_ramp_size_pass 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id
      ),
      step_ramp_size_comment = (
        SELECT step_ramp_size_comment 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id
      )
      WHERE EXISTS (
        SELECT 1 
        FROM structure_assessments 
        WHERE structure_assessments.inspection_id = inspections.id 
        AND (structure_assessments.step_ramp_size IS NOT NULL 
          OR structure_assessments.step_ramp_size_pass IS NOT NULL
          OR structure_assessments.step_ramp_size_comment IS NOT NULL)
      )
    SQL

    # Remove fields from structure_assessments
    remove_column :structure_assessments, :step_ramp_size
    remove_column :structure_assessments, :step_ramp_size_pass
    remove_column :structure_assessments, :step_ramp_size_comment
  end
end
