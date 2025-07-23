class RemoveLockStitchingFromStructureAssessments < ActiveRecord::Migration[8.0]
  def change
    remove_column :structure_assessments, :uses_lock_stitching_pass, :boolean
    remove_column :structure_assessments, :uses_lock_stitching_comment, :text
  end
end
