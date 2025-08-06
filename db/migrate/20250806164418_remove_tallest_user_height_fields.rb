class RemoveTallestUserHeightFields < ActiveRecord::Migration[8.0]
  def change
    # Remove tallest_user_height related fields
    remove_column :user_height_assessments, :tallest_user_height, :decimal
    remove_column :user_height_assessments, :tallest_user_height_pass, :boolean
    remove_column :user_height_assessments, :tallest_user_height_comment, :text
  end
end
