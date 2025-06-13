class RemoveAnchorageFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove anchorage fields that are duplicated in anchorage_assessments table
    remove_column :inspections, :num_low_anchors, :integer
    remove_column :inspections, :num_high_anchors, :integer
    remove_column :inspections, :num_low_anchors_comment, :string
    remove_column :inspections, :num_high_anchors_comment, :string
  end
end