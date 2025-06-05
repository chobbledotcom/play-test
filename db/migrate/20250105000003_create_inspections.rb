class CreateInspections < ActiveRecord::Migration[7.0]
  def change
    create_table :inspections, id: false do |t|
      t.string :id, primary_key: true, null: false, limit: 12
      t.references :user, null: false, foreign_key: true
      t.string :unit_id, null: false, limit: 12
      t.string :inspector_company_id, null: false, limit: 12
      t.date :inspection_date, null: false
      t.string :place_inspected, null: false
      t.string :rpii_registration_number, null: false
      t.string :unique_report_number, null: false
      t.string :inspection_company_name, null: false
      t.string :status, default: 'draft'
      t.boolean :passed
      t.datetime :finalized_at
      t.references :finalized_by, foreign_key: { to_table: :users }
      t.text :general_notes
      t.text :recommendations
      t.string :weather_conditions
      t.decimal :ambient_temperature, precision: 5, scale: 2
      t.string :inspector_signature
      t.datetime :signature_timestamp
      
      t.timestamps
    end
    
    add_foreign_key :inspections, :units, column: :unit_id, primary_key: :id
    add_foreign_key :inspections, :inspector_companies, column: :inspector_company_id, primary_key: :id
    
    add_index :inspections, [:user_id, :unique_report_number], unique: true
    add_index :inspections, :inspection_date
    add_index :inspections, :status
    add_index :inspections, :passed
    add_index :inspections, :unit_id
    add_index :inspections, :inspector_company_id
  end
end