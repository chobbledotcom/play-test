class RemoveNettingCommentFromStructureAssessments <
  ActiveRecord::Migration[8.0]
  def change
    # Remove orphaned field that is not used anywhere in the codebase
    # Only exists in schema.rb and migrations, with no references
    # in models, views, or tests
    remove_column :structure_assessments, :netting_comment, :string
  end
end
