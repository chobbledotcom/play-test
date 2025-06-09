class AddCompleteDateToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :complete_date, :datetime
    
    # Migrate existing data: set complete_date for all complete inspections
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE inspections 
          SET complete_date = updated_at 
          WHERE status = 'complete'
        SQL
      end
    end
  end
end
