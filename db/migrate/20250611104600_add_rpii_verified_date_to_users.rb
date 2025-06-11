class AddRpiiVerifiedDateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :rpii_verified_date, :datetime
  end
end
