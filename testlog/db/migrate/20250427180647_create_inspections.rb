class CreateInspections < ActiveRecord::Migration[7.2]
  def change
    create_table :inspections do |t|
      t.datetime :inspection_date
      t.datetime :reinspection_date
      t.string :inspector
      t.string :serial
      t.string :description
      t.string :location
      t.integer :equipment_class
      t.boolean :visual_pass
      t.integer :fuse_rating
      t.decimal :earth_ohms
      t.integer :insulation_mohms
      t.decimal :leakage
      t.boolean :passed
      t.text :comments
      t.string :image_path
      t.string :user_id, null: false, limit: 12

      t.timestamps
    end
    add_index :inspections, :serial
    add_foreign_key :inspections, :users
  end
end
