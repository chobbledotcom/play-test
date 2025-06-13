class RemoveStructureFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove structure fields that are duplicated in structure_assessments table

    # Measurement fields
    remove_column :inspections, :stitch_length, :decimal
    remove_column :inspections, :evacuation_time, :decimal
    remove_column :inspections, :unit_pressure_value, :decimal
    remove_column :inspections, :blower_tube_length, :decimal
    remove_column :inspections, :step_size_value, :decimal
    remove_column :inspections, :fall_off_height_value, :decimal
    remove_column :inspections, :trough_depth_value, :decimal
    remove_column :inspections, :trough_width_value, :decimal

    # Pass/fail fields
    remove_column :inspections, :trough_pass, :boolean
    remove_column :inspections, :entrapment_pass, :boolean
    remove_column :inspections, :markings_id_pass, :boolean
    remove_column :inspections, :grounding_pass, :boolean
  end
end
