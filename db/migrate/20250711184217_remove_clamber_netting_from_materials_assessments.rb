class RemoveClamberNettingFromMaterialsAssessments < ActiveRecord::Migration[8.0]
  def change
    remove_column :materials_assessments, :clamber_netting_pass, :boolean
    remove_column :materials_assessments, :clamber_netting_comment, :text
  end
end
