class AddPassFieldsToUserHeightAssessment < ActiveRecord::Migration[8.0]
  def change
    # Add pass/fail fields for user height assessments
    add_column :user_height_assessments, :height_requirements_pass, :boolean
    add_column :user_height_assessments, :permanent_roof_pass, :boolean
    add_column :user_height_assessments, :user_capacity_pass, :boolean
    add_column :user_height_assessments, :play_area_pass, :boolean
    add_column :user_height_assessments, :negative_adjustments_pass, :boolean

    # Add comment fields for the pass/fail assessments
    add_column :user_height_assessments, :height_requirements_comment, :text
    add_column :user_height_assessments, :permanent_roof_pass_comment, :text
    add_column :user_height_assessments, :user_capacity_comment, :text
    add_column :user_height_assessments, :play_area_comment, :text
    add_column :user_height_assessments, :negative_adjustments_comment, :text
  end
end
