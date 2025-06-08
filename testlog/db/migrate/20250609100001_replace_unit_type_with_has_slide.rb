class ReplaceUnitTypeWithHasSlide < ActiveRecord::Migration[8.0]
  def change
    # Add has_slide to both units and inspections tables
    add_column :units, :has_slide, :boolean, default: false, null: false
    add_column :inspections, :has_slide, :boolean, default: false, null: false

    # Migrate existing data
    reversible do |dir|
      dir.up do
        # Set has_slide to true for units that are slides or combo units
        execute <<-SQL
          UPDATE units 
          SET has_slide = true 
          WHERE unit_type IN ('slide', 'combo_unit')
        SQL

        # Update existing inspections based on their unit's type
        execute <<-SQL
          UPDATE inspections 
          SET has_slide = true 
          WHERE unit_id IN (
            SELECT id FROM units WHERE unit_type IN ('slide', 'combo_unit')
          )
        SQL
      end
    end

    # Remove the unit_type column
    remove_column :units, :unit_type, :string
  end
end
