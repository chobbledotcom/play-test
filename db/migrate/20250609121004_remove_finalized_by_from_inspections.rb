class RemoveFinalizedByFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Check if columns exist before removing them
    if column_exists?(:inspections, :finalized_by_id)
      # Remove the foreign key if it exists
      begin
        remove_foreign_key :inspections, column: :finalized_by_id
      rescue
        # Foreign key doesn't exist, continue
      end

      # Remove the index if it exists
      remove_index :inspections, :finalized_by_id if index_exists?(:inspections, :finalized_by_id)

      # Remove the column
      remove_column :inspections, :finalized_by_id, :string
    end

    # Also remove finalized_at since it's related
    if column_exists?(:inspections, :finalized_at)
      remove_column :inspections, :finalized_at, :datetime
    end
  end
end
