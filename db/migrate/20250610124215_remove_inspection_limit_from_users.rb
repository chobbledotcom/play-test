class RemoveInspectionLimitFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :inspection_limit, :integer
  end
end
