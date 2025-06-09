class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: {type: :string, limit: 12} do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :admin, default: false
      t.integer :inspection_limit, default: 10, null: false
      t.datetime :last_active_at
      t.string :time_display, default: "date"

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
