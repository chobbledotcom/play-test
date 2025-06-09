class AddStepRampSizeToUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :units, :step_ramp_size, :decimal
  end
end
