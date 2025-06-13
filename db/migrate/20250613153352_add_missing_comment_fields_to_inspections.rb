class AddMissingCommentFieldsToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :step_ramp_size_comment, :string, limit: 1000
    add_column :inspections, :critical_fall_off_height_comment, :string, limit: 1000
  end
end
