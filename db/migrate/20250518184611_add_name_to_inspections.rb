class AddNameToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :name, :string
  end
end
