class ReplaceUserCountFieldsWithCustomComments < ActiveRecord::Migration[8.0]
  def change
    # Remove the user_count_at_maximum_user_height field
    remove_column :user_height_assessments,
      :user_count_at_maximum_user_height, :integer

    # Add the new custom user height comment field
    add_column :user_height_assessments, :custom_user_height_comment, :text
  end
end
