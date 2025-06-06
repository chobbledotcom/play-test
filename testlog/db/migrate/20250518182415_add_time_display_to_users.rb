class AddTimeDisplayToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :time_display, :string, default: "date"
  end
end
