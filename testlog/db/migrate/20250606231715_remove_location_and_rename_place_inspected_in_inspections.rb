class RemoveLocationAndRenamePlaceInspectedInInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove the location column since we only want one location field
    remove_column :inspections, :location, :string

    # Rename place_inspected to inspection_location for clarity
    rename_column :inspections, :place_inspected, :inspection_location
  end
end
