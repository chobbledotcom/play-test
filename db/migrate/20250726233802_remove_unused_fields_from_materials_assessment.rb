class RemoveUnusedFieldsFromMaterialsAssessment < ActiveRecord::Migration[8.0]
  def change
    # Remove orphaned comment fields that are not used anywhere in the codebase
    # These fields only exist in schema.rb and migrations, with no references
    # in models, views, or tests
    remove_column :materials_assessments, :marking_comment, :text
    remove_column :materials_assessments, :instructions_comment, :text
    remove_column :materials_assessments, :inflated_stability_comment, :text
    remove_column :materials_assessments, :protrusions_comment, :text
    remove_column :materials_assessments, :critical_defects_comment, :text
  end
end
