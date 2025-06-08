class AddTotallyEnclosedFieldsToUnits < ActiveRecord::Migration[7.0]
  def change
    # Add boolean to indicate if unit is totally enclosed
    add_column :units, :is_totally_enclosed, :boolean, default: false

    # Remove 'totally_enclosed' from unit_type by updating existing records
    reversible do |dir|
      dir.up do
        # Convert any units with unit_type 'totally_enclosed' to appropriate type with is_totally_enclosed true
        execute <<-SQL
          UPDATE units 
          SET is_totally_enclosed = true, 
              unit_type = 'bounce_house'
          WHERE unit_type = 'totally_enclosed'
        SQL
      end
    end
  end
end
