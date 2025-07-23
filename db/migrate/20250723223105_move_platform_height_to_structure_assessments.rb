class MovePlatformHeightToStructureAssessments < ActiveRecord::Migration[8.0]
  def up
    add_platform_height_to_structure_assessments
    migrate_platform_height_data_forward
    remove_platform_height_from_user_height_assessments
  end

  def down
    add_platform_height_to_user_height_assessments
    migrate_platform_height_data_backward
    remove_platform_height_from_structure_assessments
  end

  private

  def add_platform_height_to_structure_assessments
    add_column :structure_assessments, :platform_height, :decimal,
      precision: 8, scale: 2
    add_column :structure_assessments, :platform_height_pass, :boolean
    add_column :structure_assessments, :platform_height_comment, :text
  end

  def add_platform_height_to_user_height_assessments
    add_column :user_height_assessments, :platform_height, :decimal,
      precision: 8, scale: 2
    add_column :user_height_assessments, :platform_height_comment, :text
  end

  def migrate_platform_height_data_forward
    execute <<-SQL
      UPDATE structure_assessments
      SET platform_height = user_height_assessments.platform_height,
          platform_height_comment =
            user_height_assessments.platform_height_comment
      FROM user_height_assessments
      WHERE structure_assessments.inspection_id =
            user_height_assessments.inspection_id
        AND user_height_assessments.platform_height IS NOT NULL
    SQL
  end

  def migrate_platform_height_data_backward
    execute <<-SQL
      UPDATE user_height_assessments
      SET platform_height = structure_assessments.platform_height,
          platform_height_comment =
            structure_assessments.platform_height_comment
      FROM structure_assessments
      WHERE user_height_assessments.inspection_id =
            structure_assessments.inspection_id
        AND structure_assessments.platform_height IS NOT NULL
    SQL
  end

  def remove_platform_height_from_user_height_assessments
    remove_column :user_height_assessments, :platform_height
    remove_column :user_height_assessments, :platform_height_comment
  end

  def remove_platform_height_from_structure_assessments
    remove_column :structure_assessments, :platform_height
    remove_column :structure_assessments, :platform_height_pass
    remove_column :structure_assessments, :platform_height_comment
  end
end
