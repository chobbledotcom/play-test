class RemoveRedundantFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    remove_column :inspections, :rpii_registration_number, :string
    remove_column :inspections, :inspection_company_name, :string
    remove_column :inspections, :inspector, :string
    remove_column :inspections, :reinspection_date, :datetime
  end
end
