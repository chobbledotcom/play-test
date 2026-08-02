# typed: false

class ChangeStructureNaPassFieldsToInteger < ActiveRecord::Migration[8.0]
  FIELDS = %i[
    critical_fall_off_height_pass
    grounding_pass
    platform_height_pass
    step_ramp_size_pass
    trough_pass
  ].freeze

  def up
    FIELDS.each do |field|
      # Convert boolean values to integers: true -> 1, false -> 0, null -> null
      execute <<-SQL
        UPDATE structure_assessments
        SET #{field} = CASE
          WHEN #{field} = true THEN 1
          WHEN #{field} = false THEN 0
          ELSE NULL
        END
      SQL

      change_column :structure_assessments, field, :integer, limit: 1
    end
  end

  def down
    FIELDS.each do |field|
      change_column :structure_assessments, field, :boolean

      # Convert integers back to booleans: 1 -> true, 0 -> false, others -> null
      execute <<-SQL
        UPDATE structure_assessments
        SET #{field} = CASE
          WHEN #{field} = 1 THEN true
          WHEN #{field} = 0 THEN false
          ELSE NULL
        END
      SQL
    end
  end
end
