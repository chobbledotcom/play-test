class RenameTroughDepthValueFields < ActiveRecord::Migration[8.0]
  def change
    # Rename trough_depth_value to trough_depth
    rename_column :structure_assessments, :trough_depth_value, :trough_depth
    rename_column :structure_assessments, :trough_depth_value_pass, :trough_depth_pass
    
    # Remove duplicate comment field (trough_depth_comment already exists)
    remove_column :structure_assessments, :trough_depth_value_comment, :text
    
    # Also rename trough_width_value to trough_width for consistency
    rename_column :structure_assessments, :trough_width_value, :trough_width
  end
end
