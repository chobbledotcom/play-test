# frozen_string_literal: true

class CreateUserSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sessions do |t|
      t.references :user, type: :string, limit: 12, null: false, foreign_key: true
      t.string :session_token, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_active_at, null: false

      t.timestamps
    end

    add_index :user_sessions, :session_token, unique: true
    add_index :user_sessions, %i[user_id last_active_at]

    add_foreign_key :user_sessions, :users
  end
end
