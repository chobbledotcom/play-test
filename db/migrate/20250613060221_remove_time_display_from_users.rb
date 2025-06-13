class RemoveTimeDisplayFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :time_display, :string
  end
end
