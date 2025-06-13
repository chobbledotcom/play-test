class FixMaterialsAssessmentColumnNames < ActiveRecord::Migration[8.0]
  def change
    # Undo the over-elaboration
    rename_column :materials_assessments, :zips_integrity_pass, :zips_pass
    rename_column :materials_assessments, :zips_integrity_comment, :zips_comment
    
    rename_column :materials_assessments, :windows_integrity_pass, :windows_pass
    rename_column :materials_assessments, :windows_integrity_comment, :windows_comment
    
    rename_column :materials_assessments, :artwork_attachment_pass, :artwork_pass
    rename_column :materials_assessments, :artwork_attachment_comment, :artwork_comment
    
    rename_column :materials_assessments, :thread_strength_pass, :thread_pass
    rename_column :materials_assessments, :thread_strength_comment, :thread_comment
    
    # Rename rope_size to ropes (including the number field)
    rename_column :materials_assessments, :rope_size, :ropes
    rename_column :materials_assessments, :rope_size_pass, :ropes_pass
    rename_column :materials_assessments, :rope_size_comment, :ropes_comment
  end
end
