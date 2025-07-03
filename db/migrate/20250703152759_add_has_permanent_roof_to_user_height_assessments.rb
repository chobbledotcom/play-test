class AddHasPermanentRoofToUserHeightAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :user_height_assessments, :has_permanent_roof, :boolean
    add_column :user_height_assessments, :has_permanent_roof_comment, :text
  end
end
