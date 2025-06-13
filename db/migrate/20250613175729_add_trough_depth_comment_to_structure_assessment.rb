class AddTroughDepthCommentToStructureAssessment < ActiveRecord::Migration[8.0]
  def change
    add_column :structure_assessments, :trough_depth_value_comment, :text
  end
end
