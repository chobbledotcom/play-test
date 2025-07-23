class RenameOwnerToOperatorInUnits < ActiveRecord::Migration[8.0]
  def change
    rename_column :units, :owner, :operator
  end
end
