class RenameMaterialsAssessmentColumns < ActiveRecord::Migration[8.0]
  def change
    # Rename columns to be more descriptive
    rename_column :materials_assessments, :fabric_pass, :fabric_strength_pass
    rename_column :materials_assessments, :fabric_comment, :fabric_strength_comment

    rename_column :materials_assessments, :thread_pass, :thread_strength_pass
    rename_column :materials_assessments, :thread_comment, :thread_strength_comment

    rename_column :materials_assessments, :clamber_pass, :clamber_netting_pass
    rename_column :materials_assessments, :clamber_comment, :clamber_netting_comment

    rename_column :materials_assessments, :zips_pass, :zips_integrity_pass
    rename_column :materials_assessments, :zips_comment, :zips_integrity_comment

    rename_column :materials_assessments, :windows_pass, :windows_integrity_pass
    rename_column :materials_assessments, :windows_comment, :windows_integrity_comment

    rename_column :materials_assessments, :artwork_pass, :artwork_attachment_pass
    rename_column :materials_assessments, :artwork_comment, :artwork_attachment_comment
  end
end
