class AddUserCountAtMaximumUserHeightToUserHeightAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :user_height_assessments, :user_count_at_maximum_user_height, :integer
  end
end
