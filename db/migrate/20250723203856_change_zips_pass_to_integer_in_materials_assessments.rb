class ChangeZipsPassToIntegerInMaterialsAssessments <
  ActiveRecord::Migration[8.0]
  def up
    # Convert boolean values to integers: true -> 1, false -> 0, null -> null
    execute <<-SQL
      UPDATE materials_assessments#{" "}
      SET zips_pass = CASE#{" "}
        WHEN zips_pass = true THEN 1
        WHEN zips_pass = false THEN 0
        ELSE NULL
      END
    SQL

    # Change column type from boolean to integer with limit 1 (tinyint)
    change_column :materials_assessments, :zips_pass, :integer, limit: 1
  end

  def down
    # Change back to boolean
    change_column :materials_assessments, :zips_pass, :boolean

    # Convert integer values back to booleans:
    # 1 -> true, 0 -> false, others -> null
    execute <<-SQL
      UPDATE materials_assessments#{" "}
      SET zips_pass = CASE#{" "}
        WHEN zips_pass = 1 THEN true
        WHEN zips_pass = 0 THEN false
        ELSE NULL
      END
    SQL
  end
end
