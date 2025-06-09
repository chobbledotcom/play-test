class AddFivePassFailFieldsToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :clamber_netting_pass, :boolean
    add_column :inspections, :retention_netting_pass, :boolean
    add_column :inspections, :zips_pass, :boolean
    add_column :inspections, :windows_pass, :boolean
    add_column :inspections, :artwork_pass, :boolean
  end
end
