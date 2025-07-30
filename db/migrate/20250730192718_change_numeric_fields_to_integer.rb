class ChangeNumericFieldsToInteger < ActiveRecord::Migration[7.1]
  def up
    change_column :structure_assessments, :step_ramp_size, :integer
    change_column :materials_assessments, :ropes, :integer
  end

  def down
    change_column :structure_assessments, :step_ramp_size, :decimal,
      precision: 8, scale: 2
    change_column :materials_assessments, :ropes, :decimal,
      precision: 8, scale: 2
  end
end
