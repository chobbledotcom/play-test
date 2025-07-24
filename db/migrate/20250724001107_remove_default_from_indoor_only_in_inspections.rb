class RemoveDefaultFromIndoorOnlyInInspections < ActiveRecord::Migration[8.0]
  def change
    change_column_default :inspections, :indoor_only, from: false, to: nil
  end
end
