# typed: false

class RemoveManufacturerSerialIndexFromUnits < ActiveRecord::Migration[8.0]
  def change
    remove_index :units, [:manufacturer, :serial],
      name: "index_units_on_manufacturer_and_serial"
  end
end
