class RemoveStatusFromInspections < ActiveRecord::Migration[8.0]
  def change
    remove_column :inspections, :status, :string
  end
end
