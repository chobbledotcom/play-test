class RemoveTroughPassFieldsFromStructureAssessments <
    ActiveRecord::Migration[8.0]
  def change
    remove_column :structure_assessments,
      :trough_depth_pass, :boolean
    remove_column :structure_assessments,
      :trough_adjacent_panel_width_pass, :boolean
  end
end
