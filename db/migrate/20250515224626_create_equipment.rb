class CreateEquipment < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment, id: {type: :string, limit: 12} do |t|
      t.string :name
      t.string :location
      t.string :serial
      t.string :user_id, null: false, limit: 12

      t.timestamps
    end

    add_index :equipment, :serial
    add_foreign_key :equipment, :users
  end
end
