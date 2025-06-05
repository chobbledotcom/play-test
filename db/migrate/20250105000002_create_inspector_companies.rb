class CreateInspectorCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :inspector_companies, id: false do |t|
      t.string :id, primary_key: true, null: false, limit: 12
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :rpii_registration_number, null: false
      t.string :email
      t.string :phone, null: false
      t.text :address, null: false
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country, default: 'UK'
      t.boolean :rpii_verified, default: false
      t.boolean :active, default: true
      t.text :notes

      t.timestamps
    end

    add_index :inspector_companies, :rpii_registration_number, unique: true
    add_index :inspector_companies, :user_id
    add_index :inspector_companies, :rpii_verified
    add_index :inspector_companies, :active
  end
end
