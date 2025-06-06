class AddManufacturerToEquipment < ActiveRecord::Migration[8.0]
  def change
    add_column :equipment, :manufacturer, :string
  end
end
