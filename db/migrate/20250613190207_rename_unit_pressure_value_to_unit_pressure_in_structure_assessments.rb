class RenameUnitPressureValueToUnitPressureInStructureAssessments < ActiveRecord::Migration[8.0]
  def change
    rename_column :structure_assessments, :unit_pressure_value, :unit_pressure
    # Note: unit_pressure_comment already exists, keeping unit_pressure_value_comment for consistency
  end
end
