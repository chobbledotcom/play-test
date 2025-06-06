class AddEquipmentToInspections < ActiveRecord::Migration[8.0]
  def change
    add_reference :inspections, :equipment, null: true, foreign_key: true, type: :string
  end
end
