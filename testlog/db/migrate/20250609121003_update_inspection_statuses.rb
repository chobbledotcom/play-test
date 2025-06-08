class UpdateInspectionStatuses < ActiveRecord::Migration[8.0]
  def up
    # Update all existing statuses to the new simplified system
    # completed, finalized, in_progress -> complete
    # draft -> draft (unchanged)
    execute <<-SQL
      UPDATE inspections 
      SET status = 'complete' 
      WHERE status IN ('completed', 'finalized', 'in_progress')
    SQL
  end

  def down
    # If we need to rollback, set all complete back to completed
    execute <<-SQL
      UPDATE inspections 
      SET status = 'completed' 
      WHERE status = 'complete'
    SQL
  end
end
