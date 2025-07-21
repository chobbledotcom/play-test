class AddInspectionTypeToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :inspection_type, :string, null: false, default: "BOUNCY_CASTLE"
    add_index :inspections, :inspection_type
  end
end
