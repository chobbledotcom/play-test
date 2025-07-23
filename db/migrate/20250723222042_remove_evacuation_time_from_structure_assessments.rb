class RemoveEvacuationTimeFromStructureAssessments <
  ActiveRecord::Migration[8.0]
  def change
    remove_column :structure_assessments, :evacuation_time, :decimal
  end
end
