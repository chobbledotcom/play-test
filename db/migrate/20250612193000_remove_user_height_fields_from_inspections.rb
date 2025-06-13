class RemoveUserHeightFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove user height fields that are duplicated in user_height_assessments table

    # Height and capacity fields
    remove_column :inspections, :containing_wall_height, :decimal
    remove_column :inspections, :platform_height, :decimal
    remove_column :inspections, :tallest_user_height, :decimal
    remove_column :inspections, :users_at_1000mm, :integer
    remove_column :inspections, :users_at_1200mm, :integer
    remove_column :inspections, :users_at_1500mm, :integer
    remove_column :inspections, :users_at_1800mm, :integer

    # Play area dimensions
    remove_column :inspections, :play_area_length, :decimal
    remove_column :inspections, :play_area_width, :decimal
    remove_column :inspections, :negative_adjustment, :decimal
    remove_column :inspections, :permanent_roof, :boolean

    # Comments
    remove_column :inspections, :containing_wall_height_comment, :string
    remove_column :inspections, :platform_height_comment, :string
    remove_column :inspections, :permanent_roof_comment, :string
    remove_column :inspections, :play_area_length_comment, :string
    remove_column :inspections, :play_area_width_comment, :string
    remove_column :inspections, :negative_adjustment_comment, :string
  end
end
