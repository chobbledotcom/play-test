class AddUnitPressureValueCommentToStructureAssessment < ActiveRecord::Migration[8.0]
  def change
    add_column :structure_assessments, :unit_pressure_value_comment, :text
  end
end
