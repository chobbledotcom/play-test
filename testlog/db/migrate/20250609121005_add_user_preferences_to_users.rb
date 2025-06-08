class AddUserPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_inspection_location, :string
    add_column :users, :theme, :string, default: "light"
  end
end
