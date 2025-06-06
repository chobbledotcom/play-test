class CreateEquipment < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment, id: {type: :string, limit: 12} do |t|
      t.string :name
      t.string :location
      t.string :serial
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :equipment, :serial
  end
end
