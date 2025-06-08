class AddIsTotallyEnclosedToInspections < ActiveRecord::Migration[8.0]
  def change
    # Add is_totally_enclosed to inspections table
    add_column :inspections, :is_totally_enclosed, :boolean, default: false, null: false

    # Migrate existing data based on their units
    reversible do |dir|
      dir.up do
        # Update existing inspections based on their unit's is_totally_enclosed value
        execute <<-SQL
          UPDATE inspections 
          SET is_totally_enclosed = true 
          WHERE unit_id IN (
            SELECT id FROM units WHERE is_totally_enclosed = true
          )
        SQL
      end
    end
  end
end
