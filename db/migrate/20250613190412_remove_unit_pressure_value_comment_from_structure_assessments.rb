class RemoveUnitPressureValueCommentFromStructureAssessments < ActiveRecord::Migration[8.0]
  def change
    remove_column :structure_assessments, :unit_pressure_value_comment, :text
  end
end
