class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :user, type: :string, limit: 12, null: false, foreign_key: true
      t.string :action, null: false
      t.string :resource_type, null: false
      t.string :resource_id, limit: 12
      t.text :details
      t.json :changed_data
      t.json :metadata
      t.datetime :created_at, null: false

      t.index [:user_id, :created_at]
      t.index [:resource_type, :resource_id]
      t.index [:action]
      t.index :created_at
    end
  end
end
