class CreateUnits < ActiveRecord::Migration[7.0]
  def change
    create_table :units, id: false do |t|
      t.string :id, primary_key: true, null: false, limit: 12
      t.references :user, null: false, foreign_key: true
      t.string :description, null: false
      t.string :manufacturer, null: false
      t.string :unit_type, null: false
      t.string :owner, null: false
      t.string :serial_number, null: false
      t.decimal :width, precision: 8, scale: 2, null: false
      t.decimal :length, precision: 8, scale: 2, null: false
      t.decimal :height, precision: 8, scale: 2, null: false
      t.text :notes
      t.string :model
      t.date :manufacture_date
      t.string :condition
      t.string :location
      
      t.timestamps
    end
    
    add_index :units, [:manufacturer, :serial_number], unique: true
    add_index :units, :unit_type
    add_index :units, :user_id
  end
end