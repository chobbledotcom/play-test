class RemoveUnusedCommentFieldsFromStructureAssessments < ActiveRecord::Migration[8.0]
  def change
    remove_column :structure_assessments, :tubes_present_comment, :string
    remove_column :structure_assessments, :ventilation_comment, :string
    remove_column :structure_assessments, :step_heights_comment, :string
    remove_column :structure_assessments, :opening_dimension_comment, :string
    remove_column :structure_assessments, :entrances_comment, :string
    remove_column :structure_assessments, :fabric_integrity_comment, :string
  end
end
