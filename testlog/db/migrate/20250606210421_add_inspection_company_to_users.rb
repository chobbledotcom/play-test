class AddInspectionCompanyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :inspection_company_id, :string
    add_index :users, :inspection_company_id
  end
end
