class RemoveNameFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :name, :string
  end
end
