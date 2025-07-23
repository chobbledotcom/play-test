class RemoveStitchLengthFromStructureAssessments < ActiveRecord::Migration[8.0]
  def change
    remove_column :structure_assessments, :stitch_length, :decimal
  end
end
