class AddMissingUniqueIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add unique index for users.email
    remove_index :users, :email
    add_index :users, :email, unique: true

    # Add unique index for users.rpii_inspector_number
    # Only add if not already exists (in case of multiple runs)
    # Note: In PostgreSQL, multiple NULL values are allowed in unique indexes
    # In SQLite, this behavior depends on version but modern versions allow it
    add_index :users, :rpii_inspector_number, unique: true, where: "rpii_inspector_number IS NOT NULL"

    # Add unique index for units.serial scoped to user_id
    add_index :units, [ :serial, :user_id ], unique: true

    # The inspections table already has a proper unique index
    # on ["user_id", "unique_report_number"], which handles NULL values correctly
  end
end
