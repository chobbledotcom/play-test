class AddCommentFieldsToAnchorageAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :anchorage_assessments, :num_low_anchors_comment, :text
    add_column :anchorage_assessments, :num_high_anchors_comment, :text
    add_column :anchorage_assessments, :num_low_anchors_pass, :boolean
    add_column :anchorage_assessments, :num_high_anchors_pass, :boolean
  end
end
