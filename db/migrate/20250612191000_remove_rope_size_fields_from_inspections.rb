class RemoveRopeSizeFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove rope size fields that are duplicated in materials_assessments table
    remove_column :inspections, :rope_size, :decimal
    remove_column :inspections, :rope_size_comment, :string
  end
end