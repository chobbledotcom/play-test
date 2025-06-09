class RemoveDuplicateFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove duplicate fields from inspections - these should come from the unit
    remove_column :inspections, :serial, :string
    remove_column :inspections, :manufacturer, :string
    remove_column :inspections, :name, :string

    # Remove location from units - this should be on inspections instead
    remove_column :units, :location, :string

    # Make unit_id required on inspections
    change_column_null :inspections, :unit_id, false
  end
end
