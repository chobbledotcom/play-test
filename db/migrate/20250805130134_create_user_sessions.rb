class CreateUserSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sessions do |t|
      t.string :user_id, null: false
      t.string :session_token, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_active_at, null: false

      t.timestamps
    end

    add_index :user_sessions, :session_token, unique: true
    add_index :user_sessions, [:user_id, :last_active_at]
    add_index :user_sessions, :user_id

    add_foreign_key :user_sessions, :users
  end
end
