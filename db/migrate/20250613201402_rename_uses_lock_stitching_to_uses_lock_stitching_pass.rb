class RenameUsesLockStitchingToUsesLockStitchingPass < ActiveRecord::Migration[8.0]
  def change
    # Rename uses_lock_stitching to uses_lock_stitching_pass for consistency with pass_fail_comment pattern
    rename_column :structure_assessments, :uses_lock_stitching, :uses_lock_stitching_pass
  end
end
