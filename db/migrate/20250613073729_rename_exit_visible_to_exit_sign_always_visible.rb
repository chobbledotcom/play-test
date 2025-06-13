class RenameExitVisibleToExitSignAlwaysVisible < ActiveRecord::Migration[8.0]
  def change
    rename_column :enclosed_assessments, :exit_visible_pass, :exit_sign_always_visible_pass
    rename_column :enclosed_assessments, :exit_visible_comment, :exit_sign_always_visible_comment
  end
end
