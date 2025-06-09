class AddRiskAssessmentToUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :units, :risk_assessment, :text
  end
end
