class RenameStepSizeValueToStepSize < ActiveRecord::Migration[8.0]
  def change
    # Rename step_size_value to step_size in structure_assessments
    rename_column :structure_assessments, :step_size_value, :step_size
  end
end
