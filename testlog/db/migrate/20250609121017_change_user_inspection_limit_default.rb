class ChangeUserInspectionLimitDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :inspection_limit, from: 10, to: -1
  end
end
