class AddInspectionLimitToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :inspection_limit, :integer, default: 10, null: false
  end
end
