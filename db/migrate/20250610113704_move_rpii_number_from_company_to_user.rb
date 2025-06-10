class MoveRpiiNumberFromCompanyToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :rpii_inspector_number, :string
    remove_column :inspector_companies, :rpii_registration_number, :string
  end
end
