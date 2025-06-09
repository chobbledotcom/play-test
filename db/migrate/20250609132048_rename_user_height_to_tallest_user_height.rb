class RenameUserHeightToTallestUserHeight < ActiveRecord::Migration[8.0]
  def change
    rename_column :inspections, :user_height, :tallest_user_height
    rename_column :units, :user_height, :tallest_user_height
    rename_column :user_height_assessments, :user_height, :tallest_user_height
    rename_column :user_height_assessments, :user_height_comment, :tallest_user_height_comment
  end
end
