class RemoveInspectionLocationFromInspectionsAndUsers <
  ActiveRecord::Migration[8.0]
  def change
    remove_column :inspections, :inspection_location, :string
    remove_column :users, :default_inspection_location, :string
  end
end
