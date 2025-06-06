class RenameEquipmentToUnits < ActiveRecord::Migration[8.0]
  def change
    # Rename the equipment table to units
    rename_table :equipment, :units

    # Rename foreign key column in inspections
    rename_column :inspections, :equipment_id, :unit_id

    # Rename equipment_storage column in materials assessments if it exists
    if column_exists?(:materials_assessments, :equipment_storage)
      rename_column :materials_assessments, :equipment_storage, :unit_storage
    end
  end
end
