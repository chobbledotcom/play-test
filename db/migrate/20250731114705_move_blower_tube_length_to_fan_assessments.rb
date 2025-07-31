class MoveBlowerTubeLengthToFanAssessments < ActiveRecord::Migration[8.0]
  def up
    add_blower_tube_length_to_fan_assessments
    migrate_blower_tube_length_data_forward
    remove_blower_tube_length_from_structure_assessments
  end

  def down
    add_blower_tube_length_to_structure_assessments
    migrate_blower_tube_length_data_backward
    remove_blower_tube_length_from_fan_assessments
  end

  private

  def add_blower_tube_length_to_fan_assessments
    add_column :fan_assessments, :blower_tube_length, :decimal,
      precision: 8, scale: 2
    add_column :fan_assessments, :blower_tube_length_pass, :boolean
    add_column :fan_assessments, :blower_tube_length_comment, :text
  end

  def add_blower_tube_length_to_structure_assessments
    add_column :structure_assessments, :blower_tube_length, :decimal,
      precision: 8, scale: 2
    add_column :structure_assessments, :blower_tube_length_pass, :boolean
    add_column :structure_assessments, :blower_tube_length_comment, :text
  end

  def migrate_blower_tube_length_data_forward
    execute <<-SQL
      UPDATE fan_assessments
      SET blower_tube_length = structure_assessments.blower_tube_length,
          blower_tube_length_pass =#{" "}
            structure_assessments.blower_tube_length_pass,
          blower_tube_length_comment =#{" "}
            structure_assessments.blower_tube_length_comment
      FROM structure_assessments
      WHERE fan_assessments.inspection_id =#{" "}
            structure_assessments.inspection_id
        AND structure_assessments.blower_tube_length IS NOT NULL
    SQL
  end

  def migrate_blower_tube_length_data_backward
    execute <<-SQL
      UPDATE structure_assessments
      SET blower_tube_length = fan_assessments.blower_tube_length,
          blower_tube_length_pass = fan_assessments.blower_tube_length_pass,
          blower_tube_length_comment =#{" "}
            fan_assessments.blower_tube_length_comment
      FROM fan_assessments
      WHERE structure_assessments.inspection_id =#{" "}
            fan_assessments.inspection_id
        AND fan_assessments.blower_tube_length IS NOT NULL
    SQL
  end

  def remove_blower_tube_length_from_structure_assessments
    remove_column :structure_assessments, :blower_tube_length
    remove_column :structure_assessments, :blower_tube_length_pass
    remove_column :structure_assessments, :blower_tube_length_comment
  end

  def remove_blower_tube_length_from_fan_assessments
    remove_column :fan_assessments, :blower_tube_length
    remove_column :fan_assessments, :blower_tube_length_pass
    remove_column :fan_assessments, :blower_tube_length_comment
  end
end
