class AddAdditionalPatFieldsToInspections < ActiveRecord::Migration[7.2]
  def change
    add_column :inspections, :appliance_plug_check, :boolean, default: false
    add_column :inspections, :equipment_power, :integer
    add_column :inspections, :load_test, :boolean, default: false
    add_column :inspections, :rcd_trip_time, :decimal, precision: 5, scale: 2
    add_column :inspections, :manufacturer, :string
  end
end
