class RemoveDuplicateMaterialsFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove materials assessment fields that are duplicated in materials_assessments table
    remove_column :inspections, :retention_netting_pass, :boolean
    remove_column :inspections, :zips_pass, :boolean
    remove_column :inspections, :windows_pass, :boolean
    remove_column :inspections, :artwork_pass, :boolean
  end
end