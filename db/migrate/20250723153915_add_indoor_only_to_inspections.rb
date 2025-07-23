class AddIndoorOnlyToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :indoor_only, :boolean, default: false
  end
end
