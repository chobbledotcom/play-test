class RenameLockStitchPassToUsesLockStitching < ActiveRecord::Migration[8.0]
  def change
    # Rename lock_stitch_pass to uses_lock_stitching in structure_assessments
    rename_column :structure_assessments, :lock_stitch_pass, :uses_lock_stitching
    rename_column :structure_assessments, :lock_stitch_comment, :uses_lock_stitching_comment
  end
end
