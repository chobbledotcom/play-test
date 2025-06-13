class MoveEnclosedFieldsFromInspectionsToEnclosedAssessments < ActiveRecord::Migration[7.2]
  def up
    # Add exit_sign_visible_pass to enclosed_assessments if it doesn't exist
    unless column_exists?(:enclosed_assessments, :exit_sign_visible_pass)
      add_column :enclosed_assessments, :exit_sign_visible_pass, :boolean
    end

    # Migrate data from inspections to their associated enclosed_assessments
    execute <<-SQL
      UPDATE enclosed_assessments
      SET exit_sign_visible_pass = inspections.exit_sign_visible_pass
      FROM inspections
      WHERE enclosed_assessments.inspection_id = inspections.id
        AND inspections.exit_sign_visible_pass IS NOT NULL
    SQL

    # Remove the duplicate fields from inspections table
    remove_column :inspections, :exit_number, :integer
    remove_column :inspections, :exit_number_comment, :string
    remove_column :inspections, :exit_sign_visible_pass, :boolean
  end

  def down
    # Add the fields back to inspections
    add_column :inspections, :exit_number, :integer
    add_column :inspections, :exit_number_comment, :string, limit: 1000
    add_column :inspections, :exit_sign_visible_pass, :boolean

    # Migrate data back from enclosed_assessments to inspections
    execute <<-SQL
      UPDATE inspections
      SET exit_number = enclosed_assessments.exit_number,
          exit_number_comment = enclosed_assessments.exit_number_comment,
          exit_sign_visible_pass = enclosed_assessments.exit_sign_visible_pass
      FROM enclosed_assessments
      WHERE enclosed_assessments.inspection_id = inspections.id
    SQL

    # Remove exit_sign_visible_pass from enclosed_assessments
    remove_column :enclosed_assessments, :exit_sign_visible_pass, :boolean
  end
end