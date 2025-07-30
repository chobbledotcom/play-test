class ConvertStructureHeightFieldsToMillimeters < ActiveRecord::Migration[8.0]
  def up
    # First, convert platform_height from meters to millimeters
    execute <<-SQL
      UPDATE structure_assessments#{" "}
      SET platform_height = ROUND(platform_height * 1000)
      WHERE platform_height IS NOT NULL
    SQL

    # Convert critical_fall_off_height from meters to millimeters
    execute <<-SQL
      UPDATE structure_assessments#{" "}
      SET critical_fall_off_height = ROUND(critical_fall_off_height * 1000)
      WHERE critical_fall_off_height IS NOT NULL
    SQL

    # Then change both fields to integer type
    change_column :structure_assessments, :platform_height, :integer
    change_column :structure_assessments, :critical_fall_off_height, :integer
  end

  def down
    # Change fields back to decimal
    change_column :structure_assessments, :platform_height,
      :decimal, precision: 8, scale: 2
    change_column :structure_assessments, :critical_fall_off_height,
      :decimal, precision: 8, scale: 2

    # Convert platform_height back from millimeters to meters
    execute <<-SQL
      UPDATE structure_assessments#{" "}
      SET platform_height = platform_height / 1000.0
      WHERE platform_height IS NOT NULL
    SQL

    # Convert critical_fall_off_height back from millimeters to meters
    execute <<-SQL
      UPDATE structure_assessments#{" "}
      SET critical_fall_off_height = critical_fall_off_height / 1000.0
      WHERE critical_fall_off_height IS NOT NULL
    SQL
  end
end
