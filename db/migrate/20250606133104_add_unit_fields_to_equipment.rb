class AddUnitFieldsToEquipment < ActiveRecord::Migration[8.0]
  def change
    # Add new Unit-specific fields while maintaining existing Equipment functionality
    add_column :equipment, :description, :string
    add_column :equipment, :unit_type, :string
    add_column :equipment, :owner, :string
    add_column :equipment, :serial_number, :string
    add_column :equipment, :width, :decimal, precision: 8, scale: 2
    add_column :equipment, :length, :decimal, precision: 8, scale: 2
    add_column :equipment, :height, :decimal, precision: 8, scale: 2
    add_column :equipment, :notes, :text
    add_column :equipment, :model, :string
    add_column :equipment, :manufacture_date, :date
    add_column :equipment, :condition, :string
    # location already exists in equipment table

    # Add indexes for new fields
    add_index :equipment, :unit_type
    add_index :equipment, [:manufacturer, :serial_number], unique: true, name: "index_equipment_on_manufacturer_and_serial_number"
  end
end
