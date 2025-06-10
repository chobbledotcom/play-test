class AddContactFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :phone, :string
    add_column :users, :address, :text
    add_column :users, :country, :string
    add_column :users, :postal_code, :string
    
    # Remove state field from inspector_companies as it's not needed
    remove_column :inspector_companies, :state, :string
  end
end
