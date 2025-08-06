class RemoveMaximumUserHeightFields < ActiveRecord::Migration[8.0]
  def change
    # Remove maximum_user_height related fields
    remove_column :user_height_assessments, :maximum_user_height, :decimal
    remove_column :user_height_assessments, :maximum_user_height_pass, :boolean
    remove_column :user_height_assessments, :maximum_user_height_comment, :text
  end
end
