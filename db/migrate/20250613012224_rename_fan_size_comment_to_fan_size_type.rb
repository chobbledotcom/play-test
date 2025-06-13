class RenameFanSizeCommentToFanSizeType < ActiveRecord::Migration[8.0]
  def change
    rename_column :fan_assessments, :fan_size_comment, :fan_size_type
  end
end
