# typed: false
# frozen_string_literal: true

class MigrateOperatorFromUnitsToInspections < ActiveRecord::Migration[8.0]
  def up
    # Copy operator values from units to inspections
    execute <<~SQL
      UPDATE inspections
      SET operator = (
        SELECT units.operator
        FROM units
        WHERE units.id = inspections.unit_id
      )
      WHERE unit_id IS NOT NULL
    SQL
  end

  def down
    # No rollback needed - the operator data still exists on units
    # Clear the operator column on inspections
    execute "UPDATE inspections SET operator = NULL"
  end
end
