class MakeUnitOptionalInInspections < ActiveRecord::Migration[8.0]
  def change
    change_column_null :inspections, :unit_id, true
  end
end
