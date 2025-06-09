class AddStepRampSizeToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :step_ramp_size, :decimal
    add_column :inspections, :step_ramp_size_pass, :boolean
  end
end
